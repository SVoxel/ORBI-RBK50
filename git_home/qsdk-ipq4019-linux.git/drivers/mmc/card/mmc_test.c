/*
 *  linux/drivers/mmc/card/mmc_test.c
 *
 *  Copyright 2007-2008 Pierre Ossman
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 */

#include <linux/mmc/core.h>
#include <linux/mmc/card.h>
#include <linux/mmc/host.h>
#include <linux/mmc/mmc.h>
#include <linux/slab.h>

#include <linux/scatterlist.h>
#include <linux/swap.h>		/* For nr_free_buffer_pages() */
#include <linux/list.h>

#include <linux/debugfs.h>
#include <linux/uaccess.h>
#include <linux/seq_file.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/ctype.h>
#include <linux/parport.h>
#include <linux/list.h>
#include <linux/notifier.h>
#include <linux/reboot.h>
#include <linux/kdebug.h>
#include <linux/string.h>

#define RESULT_OK		0
#define RESULT_FAIL		1
#define RESULT_UNSUP_HOST	2
#define RESULT_UNSUP_CARD	3

#define BUFFER_ORDER		2
#define BUFFER_SIZE		(PAGE_SIZE << BUFFER_ORDER)
#define OOPS_PAGE_SIZE 4096

/*
 * Limit the test area size to the maximum MMC HC erase group size.  Note that
 * the maximum SD allocation unit size is just 4MiB.
 */
#define TEST_AREA_MAX_SIZE (128 * 1024 * 1024)

extern int register_oom_notifier(struct notifier_block *);
static char dni_panic_buf[16384];
static int buf_length = 2;
static char dni_panic_flag[16384];
static int devaddr_flag;
static unsigned long reboot_reason_flags = 0;
extern char *flash_type_name;
extern int sysctl_save_panic_data_enable;
int mmc_dni_erase(void);
//extern  struct mmc_test_card *panic_test;
/**
 * struct mmc_test_pages - pages allocated by 'alloc_pages()'.
 * @page: first page in the allocation
 * @order: order of the number of pages allocated
 */
struct mmc_test_pages {
	struct page *page;
	unsigned int order;
};

/**
 * struct mmc_test_mem - allocated memory.
 * @arr: array of allocations
 * @cnt: number of allocations
 */
struct mmc_test_mem {
	struct mmc_test_pages *arr;
	unsigned int cnt;
};

/**
 * struct mmc_test_area - information for performance tests.
 * @max_sz: test area size (in bytes)
 * @dev_addr: address on card at which to do performance tests
 * @max_tfr: maximum transfer size allowed by driver (in bytes)
 * @max_segs: maximum segments allowed by driver in scatterlist @sg
 * @max_seg_sz: maximum segment size allowed by driver
 * @blocks: number of (512 byte) blocks currently mapped by @sg
 * @sg_len: length of currently mapped scatterlist @sg
 * @mem: allocated memory
 * @sg: scatterlist
 */
struct mmc_test_area {
	unsigned long max_sz;
	unsigned int dev_addr;
	unsigned int max_tfr;
	unsigned int max_segs;
	unsigned int max_seg_sz;
	unsigned int blocks;
	unsigned int sg_len;
	struct mmc_test_mem *mem;
	struct scatterlist *sg;
};

/**
 * struct mmc_test_transfer_result - transfer results for performance tests.
 * @link: double-linked list
 * @count: amount of group of sectors to check
 * @sectors: amount of sectors to check in one group
 * @ts: time values of transfer
 * @rate: calculated transfer rate
 * @iops: I/O operations per second (times 100)
 */
struct mmc_test_transfer_result {
	struct list_head link;
	unsigned int count;
	unsigned int sectors;
	struct timespec ts;
	unsigned int rate;
	unsigned int iops;
};

/**
 * struct mmc_test_general_result - results for tests.
 * @link: double-linked list
 * @card: card under test
 * @testcase: number of test case
 * @result: result of test run
 * @tr_lst: transfer measurements if any as mmc_test_transfer_result
 */
struct mmc_test_general_result {
	struct list_head link;
	struct mmc_card *card;
	int testcase;
	int result;
	struct list_head tr_lst;
};

/**
 * struct mmc_test_dbgfs_file - debugfs related file.
 * @link: double-linked list
 * @card: card under test
 * @file: file created under debugfs
 */
struct mmc_test_dbgfs_file {
	struct list_head link;
	struct mmc_card *card;
	struct dentry *file;
};

/**
 * struct mmc_test_card - test information.
 * @card: card under test
 * @scratch: transfer buffer
 * @buffer: transfer buffer
 * @highmem: buffer for highmem tests
 * @area: information for performance tests
 * @gr: pointer to results of current testcase
 */
struct mmc_test_card {
	struct mmc_card	*card;

	char		scratch[BUFFER_SIZE];
	char		*buffer;
#ifdef CONFIG_HIGHMEM
	struct page	*highmem;
#endif
	struct mmc_test_area		area;
	struct mmc_test_general_result	*gr;
};

enum mmc_test_prep_media {
	MMC_TEST_PREP_NONE = 0,
	MMC_TEST_PREP_WRITE_FULL = 1 << 0,
	MMC_TEST_PREP_ERASE = 1 << 1,
};

struct mmc_test_multiple_rw {
	unsigned int *sg_len;
	unsigned int *bs;
	unsigned int len;
	unsigned int size;
	bool do_write;
	bool do_nonblock_req;
	enum mmc_test_prep_media prepare;
};

struct mmc_test_async_req {
	struct mmc_async_req areq;
	struct mmc_test_card *test;
};

/*******************************************************************/
/*  General helper functions                                       */
/*******************************************************************/

/*
 * Configure correct block size in card
 */
static int mmc_test_set_blksize(struct mmc_test_card *test, unsigned size)
{
	return mmc_set_blocklen(test->card, size);
}

/*
 * Fill in the mmc_request structure given a set of transfer parameters.
 */
static void mmc_test_prepare_mrq(struct mmc_test_card *test,
	struct mmc_request *mrq, struct scatterlist *sg, unsigned sg_len,
	unsigned dev_addr, unsigned blocks, unsigned blksz, int write)
{
	BUG_ON(!mrq || !mrq->cmd || !mrq->data || !mrq->stop);

	if (blocks > 1) {
		mrq->cmd->opcode = write ?
			MMC_WRITE_MULTIPLE_BLOCK : MMC_READ_MULTIPLE_BLOCK;
	} else {
		mrq->cmd->opcode = write ?
			MMC_WRITE_BLOCK : MMC_READ_SINGLE_BLOCK;
	}

	mrq->cmd->arg = dev_addr;
	if (!mmc_card_blockaddr(test->card))
		mrq->cmd->arg <<= 9;

	mrq->cmd->flags = MMC_RSP_R1 | MMC_CMD_ADTC;

	if (blocks == 1)
		mrq->stop = NULL;
	else {
		mrq->stop->opcode = MMC_STOP_TRANSMISSION;
		mrq->stop->arg = 0;
		mrq->stop->flags = MMC_RSP_R1B | MMC_CMD_AC;
	}

	mrq->data->blksz = blksz;
	mrq->data->blocks = blocks;
	mrq->data->flags = write ? MMC_DATA_WRITE : MMC_DATA_READ;
	mrq->data->sg = sg;
	mrq->data->sg_len = sg_len;

	mmc_set_data_timeout(mrq->data, test->card);
}

static int mmc_test_busy(struct mmc_command *cmd)
{
	return !(cmd->resp[0] & R1_READY_FOR_DATA) ||
		(R1_CURRENT_STATE(cmd->resp[0]) == R1_STATE_PRG);
}

/*
 * Wait for the card to finish the busy state
 */
static int mmc_test_wait_busy(struct mmc_test_card *test)
{
	int ret, busy;
	struct mmc_command cmd = {0};

	busy = 0;
	do {
		memset(&cmd, 0, sizeof(struct mmc_command));

		cmd.opcode = MMC_SEND_STATUS;
		cmd.arg = test->card->rca << 16;
		cmd.flags = MMC_RSP_R1 | MMC_CMD_AC;

		ret = mmc_wait_for_cmd(test->card->host, &cmd, 0);
		if (ret)
			break;

		if (!busy && mmc_test_busy(&cmd)) {
			busy = 1;
			if (test->card->host->caps & MMC_CAP_WAIT_WHILE_BUSY)
				pr_info("%s: Warning: Host did not "
					"wait for busy state to end.\n",
					mmc_hostname(test->card->host));
		}
	} while (mmc_test_busy(&cmd));

	return ret;
}

/*
 * Transfer a single sector of kernel addressable data
 */
static int mmc_test_buffer_transfer(struct mmc_test_card *test,
	u8 *buffer, unsigned addr, unsigned blksz, int write)
{
	int ret;

	struct mmc_request mrq = {0};
	struct mmc_command cmd = {0};
	struct mmc_command stop = {0};
	struct mmc_data data = {0};

	struct scatterlist sg;

	mrq.cmd = &cmd;
	mrq.data = &data;
	mrq.stop = &stop;

	sg_init_one(&sg, buffer, blksz);

	mmc_test_prepare_mrq(test, &mrq, &sg, 1, addr, 1, blksz, write);

	mmc_wait_for_req(test->card->host, &mrq);

	if (cmd.error)
		return cmd.error;
	if (data.error)
		return data.error;

	ret = mmc_test_wait_busy(test);
	if (ret)
		return ret;

	return 0;
}


/*
 * Checks that a normal transfer didn't have any errors
 */
static int mmc_test_check_result(struct mmc_test_card *test,
				 struct mmc_request *mrq)
{
	int ret;

	BUG_ON(!mrq || !mrq->cmd || !mrq->data);

	ret = 0;

	if (!ret && mrq->cmd->error)
		ret = mrq->cmd->error;
	if (!ret && mrq->data->error)
		ret = mrq->data->error;
	if (!ret && mrq->stop && mrq->stop->error)
		ret = mrq->stop->error;
	if (!ret && mrq->data->bytes_xfered !=
		mrq->data->blocks * mrq->data->blksz)
		ret = RESULT_FAIL;

	if (ret == -EINVAL)
		ret = RESULT_UNSUP_HOST;

	return ret;
}

/*
 * Tests a basic transfer with certain parameters
 */
static int mmc_test_simple_transfer(struct mmc_test_card *test,
	struct scatterlist *sg, unsigned sg_len, unsigned dev_addr,
	unsigned blocks, unsigned blksz, int write)
{
	struct mmc_request mrq = {0};
	struct mmc_command cmd = {0};
	struct mmc_command stop = {0};
	struct mmc_data data = {0};

	mrq.cmd = &cmd;
	mrq.data = &data;
	mrq.stop = &stop;

	mmc_test_prepare_mrq(test, &mrq, sg, sg_len, dev_addr,
		blocks, blksz, write);

	mmc_wait_for_req(test->card->host, &mrq);

	mmc_test_wait_busy(test);

	return mmc_test_check_result(test, &mrq);
}

static int mmc_test_transfer_for_proc(struct mmc_test_card *test,
	struct scatterlist *sg, unsigned sg_len, unsigned dev_addr,
	unsigned blocks, unsigned blksz, int write)
{
	int ret, i;
	unsigned long flags;

	 if (write) {
	 	for (i = 0;i < blocks * blksz;i++)
		{
			test->scratch[i] = dni_panic_buf[i];
		}
	} else {
		memset(test->scratch, 0, BUFFER_SIZE);
	}
	local_irq_save(flags);
	sg_copy_from_buffer(sg, sg_len, test->scratch, BUFFER_SIZE);
	local_irq_restore(flags);

	ret = mmc_test_set_blksize(test, blksz);
	if (ret)
		return ret;

	ret = mmc_test_simple_transfer(test, sg, sg_len, dev_addr,
		blocks, blksz, write);
	if (ret)
		return ret;
	
	if (write) {
		int sectors;

		ret = mmc_test_set_blksize(test, 512);
		if (ret)
			return ret;
		
		sectors = (blocks * blksz + 511) / 512;
		if ((sectors * 512) == (blocks * blksz))
			sectors++;

		if ((sectors * 512) > BUFFER_SIZE)
			return -EINVAL;

		memset(test->buffer, 0, sectors * 512);

		for (i = 0;i < sectors;i++) {
			ret = mmc_test_buffer_transfer(test,
				test->buffer + i * 512,
				dev_addr + i, 512, 0);
			if (ret)
				return ret;
		}

		for (i = 0;i < blocks * blksz;i++) {
			if (test->buffer[i] != (u8)i)
				return RESULT_FAIL;
		}

		for (;i < sectors * 512;i++) {
			if (test->buffer[i] != 0xDF)
				return RESULT_FAIL;
		}
	} else {
		local_irq_save(flags);
		sg_copy_to_buffer(sg, sg_len, test->scratch, BUFFER_SIZE);
		local_irq_restore(flags);
		if(strlen(test->scratch)>2)
		{
			strncpy(dni_panic_flag,test->scratch,4);
		}
		else
		{
			strncpy(dni_panic_flag,"0x00",4);
		}
		return 0;
	}

	return 0;
}

/*
 * Does a complete transfer test where data is also validated
 *
 * Note: mmc_test_prepare() must have been done before this call
 */
static int mmc_test_transfer(struct mmc_test_card *test,
	struct scatterlist *sg, unsigned sg_len, unsigned dev_addr,
	unsigned blocks, unsigned blksz, int write)
{
	int ret, i;
	unsigned long flags;

	if (write && strncmp(dni_panic_flag,"15", 2)) {
		for (i = 0;i < blocks * blksz;i++)
		{	
			test->scratch[i] = dni_panic_buf[i];
		}

	} else {
		memset(test->scratch, 0, BUFFER_SIZE);
	}
	local_irq_save(flags);
	sg_copy_from_buffer(sg, sg_len, test->scratch, BUFFER_SIZE);
	local_irq_restore(flags);

	ret = mmc_test_set_blksize(test, blksz);
	if (ret)
		return ret;

	ret = mmc_test_simple_transfer(test, sg, sg_len, dev_addr,
		blocks, blksz, write);
	if (ret)
		return ret;

	if (write) {
		int sectors;

		ret = mmc_test_set_blksize(test, 512);
		if (ret)
			return ret;

		sectors = (blocks * blksz + 511) / 512;
		if ((sectors * 512) == (blocks * blksz))
			sectors++;

		if ((sectors * 512) > BUFFER_SIZE)
			return -EINVAL;

		memset(test->buffer, 0, sectors * 512);

		for (i = 0;i < sectors;i++) {
			ret = mmc_test_buffer_transfer(test,
				test->buffer + i * 512,
				dev_addr + i, 512, 0);
			if (ret)
				return ret;
		}

		for (i = 0;i < blocks * blksz;i++) {
			if (test->buffer[i] != (u8)i)
				return RESULT_FAIL;
		}

		for (;i < sectors * 512;i++) {
			if (test->buffer[i] != 0xDF)
				return RESULT_FAIL;
		}
	} else {
		local_irq_save(flags);
		sg_copy_to_buffer(sg, sg_len, test->scratch, BUFFER_SIZE);
		local_irq_restore(flags);
		if(strlen(test->scratch)>2)
			{
				strncpy(dni_panic_flag,test->scratch,2);
			}
		else
			{
				strncpy(dni_panic_flag,"16",2);

			}
		return 0;
	}

	return 0;
}



/*******************************************************************/
/*  Tests                                                          */
/*******************************************************************/

struct mmc_test_case {
	const char *name;

	int (*prepare)(struct mmc_test_card *);
	int (*run)(struct mmc_test_card *);
	int (*cleanup)(struct mmc_test_card *);
};

static int mmc_test_erase(struct mmc_test_card *test)
{
	int ret;
	struct scatterlist sg;
	int i=1;

	for(i=1;i<512;i++)
	{
	ret = mmc_test_set_blksize(test, 512);
	if (ret)
		return ret;

	sg_init_one(&sg, test->buffer, 512);

	ret = mmc_test_simple_transfer(test, &sg, 1, 0x1d622+i, 1, 512, 1);
	}
	if (ret)
		return ret;
	

	return 0;
}

static int mmc_test_verify_write_for_proc(struct mmc_test_card *test)
{
	int ret;
	struct scatterlist sg;

	sg_init_one(&sg, test->buffer, 16384);

	ret = mmc_test_transfer_for_proc(test, &sg, 1, 0x1d622, 32, 512, 1);
	if (ret)
		return ret;

	return 0;
}

static int mmc_test_verify_write(struct mmc_test_card *test)
{
	int ret;
	struct scatterlist sg;

	sg_init_one(&sg, test->buffer, 16384);
	
	ret = mmc_test_transfer(test, &sg, 1, 0x1d622+devaddr_flag*32, 32, 512, 1);
	if (ret)
		return ret;

	return 0;
}

static int mmc_test_verify_read_for_proc(struct mmc_test_card *test)
{
	int ret;
	struct scatterlist sg;

	sg_init_one(&sg, test->buffer, 16384);

	ret = mmc_test_transfer_for_proc(test, &sg, 1, 0x1d622, 32, 512, 0);

	if (ret)
		return ret;

	return 0;
}

static int mmc_test_verify_read(struct mmc_test_card *test)
{
	int ret;
	struct scatterlist sg;
	int i=1;

	for(i;i<=15;i++)
	{
		sg_init_one(&sg, test->buffer, 16384);

		ret = mmc_test_transfer(test, &sg, 1, 0x1d622+i*32, 32, 512, 0);
		
		if(i==15)	
			sprintf(dni_panic_flag,"%d",i);
		if(strncmp(dni_panic_flag,"16",2)==0)
			{

				sprintf(dni_panic_flag,"%d",i);
				devaddr_flag=i;
				printk("mmc_test_verify_read_____dni_panic_flag%s\n",dni_panic_flag);
				return 0;
			}
	}	
	printk("mmc_test_verify_read_____dni_panic_flag%s\n",dni_panic_flag);
	if (ret)
		return ret;

	return 0;
}

#define ART_DEV_ADDR 0x2a22
#define BOARD_DATA_BOOT_PARTITION_OFFSET 0x128 /* board_data offset: 0x124 + SKU length 4 */
#define BOARD_DATA_BOOT_PARTITION_LENGTH 0x2 /* boot partition: 2 */
#define DEFAULT_BOOT_PARTITON1 "01" /* the default boot partition "01" */
#define DEFAULT_BOOT_PARTITON2 "02" /* the second boot partition "02" */

static int mmc_art_verify_read(struct mmc_test_card *test)
{
	int ret;
	struct scatterlist sg;
	unsigned int sg_len = 1;
	unsigned int dev_addr = ART_DEV_ADDR;
	unsigned int blocks = 1;
	unsigned int blksz = 512;
	unsigned long flags;
	char board_data[64];

	sg_init_one(&sg, test->buffer, blocks * blksz);

	memset(test->scratch, 0, blocks * blksz);
	local_irq_save(flags);
	sg_copy_from_buffer(&sg, sg_len, test->scratch, blocks * blksz);
	local_irq_restore(flags);

	ret = mmc_test_set_blksize(test, blksz);

	if (ret)
		return ret;

	ret = mmc_test_simple_transfer(test, &sg, sg_len, dev_addr,
		blocks, blksz, 0);

	if (ret)
		return ret;

	local_irq_save(flags);
	sg_copy_to_buffer(&sg, sg_len, test->scratch, blocks * blksz);
	local_irq_restore(flags);

	memset(board_data, 0, 64);
	strncpy(board_data, test->buffer+BOARD_DATA_BOOT_PARTITION_OFFSET-4, 16); /*show the board_data(SKU:4+Bootpart:2+FW:8+HW:2) */
	printk("%s: the board_data is %s\n", __func__, board_data);

	return 0;
}

static const struct mmc_test_case mmc_test_cases[] = {
	{
		.name = "mtdoops part earse test",
		.run = mmc_test_erase,
	},

	{
		.name = "Basic write (with data verification)",
		.run = mmc_test_verify_write,
	},

	{
		.name = "Basic read (with data verification)",
		.run = mmc_test_verify_read,
	},

	{
		.name = "ART read (with data verification and return)",
		.run = mmc_art_verify_read,
	},

	{
		.name = "Basic proc write (with data verification)",
		.run = mmc_test_verify_write_for_proc,
	},

	{
		.name = "Basic proc read (with data verification)",
		.run = mmc_test_verify_read_for_proc,
	},
};

static DEFINE_MUTEX(mmc_test_lock);

static LIST_HEAD(mmc_test_result);

static void mmc_test_run(struct mmc_test_card *test, int testcase)
{
	int i, ret;

	pr_info("%s: Starting tests of card %s...\n",
		mmc_hostname(test->card->host), mmc_card_id(test->card));

	mmc_claim_host(test->card->host);

	for (i = 0;i < ARRAY_SIZE(mmc_test_cases);i++) {
		struct mmc_test_general_result *gr;

		if (testcase && ((i + 1) != testcase))
			continue;

		pr_info("%s: Test case %d. %s...\n",
			mmc_hostname(test->card->host), i + 1,
			mmc_test_cases[i].name);

		if (mmc_test_cases[i].prepare) {
			ret = mmc_test_cases[i].prepare(test);
			if (ret) {
				pr_info("%s: Result: Prepare "
					"stage failed! (%d)\n",
					mmc_hostname(test->card->host),
					ret);
				continue;
			}
		}

		gr = kzalloc(sizeof(struct mmc_test_general_result),
			GFP_KERNEL);
		if (gr) {
			INIT_LIST_HEAD(&gr->tr_lst);

			/* Assign data what we know already */
			gr->card = test->card;
			gr->testcase = i;

			/* Append container to global one */
			list_add_tail(&gr->link, &mmc_test_result);

			/*
			 * Save the pointer to created container in our private
			 * structure.
			 */
			test->gr = gr;
		}

		ret = mmc_test_cases[i].run(test);
		switch (ret) {
		case RESULT_OK:
			pr_info("%s: Result: OK\n",
				mmc_hostname(test->card->host));
			break;
		case RESULT_FAIL:
			pr_info("%s: Result: FAILED\n",
				mmc_hostname(test->card->host));
			break;
		case RESULT_UNSUP_HOST:
			pr_info("%s: Result: UNSUPPORTED "
				"(by host)\n",
				mmc_hostname(test->card->host));
			break;
		case RESULT_UNSUP_CARD:
			pr_info("%s: Result: UNSUPPORTED "
				"(by card)\n",
				mmc_hostname(test->card->host));
			break;
		default:
			pr_info("%s: Result: ERROR (%d)\n",
				mmc_hostname(test->card->host), ret);
		}

		/* Save the result */
		if (gr)
			gr->result = ret;

		if (mmc_test_cases[i].cleanup) {
			ret = mmc_test_cases[i].cleanup(test);
			if (ret) {
				pr_info("%s: Warning: Cleanup "
					"stage failed! (%d)\n",
					mmc_hostname(test->card->host),
					ret);
			}
		}
	}

	mmc_release_host(test->card->host);

	pr_info("%s: Tests completed.\n",
		mmc_hostname(test->card->host));
}

static void mmc_test_free_result(struct mmc_card *card)
{
	struct mmc_test_general_result *gr, *grs;

	mutex_lock(&mmc_test_lock);

	list_for_each_entry_safe(gr, grs, &mmc_test_result, link) {
		struct mmc_test_transfer_result *tr, *trs;

		if (card && gr->card != card)
			continue;

		list_for_each_entry_safe(tr, trs, &gr->tr_lst, link) {
			list_del(&tr->link);
			kfree(tr);
		}

		list_del(&gr->link);
		kfree(gr);
	}

	mutex_unlock(&mmc_test_lock);
}

static LIST_HEAD(mmc_test_file_test);

static int mtf_test_show(struct seq_file *sf, void *data)
{
	struct mmc_card *card = (struct mmc_card *)sf->private;
	struct mmc_test_general_result *gr;

	mutex_lock(&mmc_test_lock);

	list_for_each_entry(gr, &mmc_test_result, link) {
		struct mmc_test_transfer_result *tr;

		if (gr->card != card)
			continue;

		seq_printf(sf, "Test %d: %d\n", gr->testcase + 1, gr->result);

		list_for_each_entry(tr, &gr->tr_lst, link) {
			seq_printf(sf, "%u %d %lu.%09lu %u %u.%02u\n",
				tr->count, tr->sectors,
				(unsigned long)tr->ts.tv_sec,
				(unsigned long)tr->ts.tv_nsec,
				tr->rate, tr->iops / 100, tr->iops % 100);
		}
	}

	mutex_unlock(&mmc_test_lock);

	return 0;
}

static int mtf_test_open(struct inode *inode, struct file *file)
{
	return single_open(file, mtf_test_show, inode->i_private);
}

static struct mmc_card *dni_card;
int mmc_dni_write(void)
{
	struct mmc_test_card *dni_test;

	dni_test = kzalloc(sizeof(struct mmc_test_card), GFP_KERNEL);
	if (!dni_test)
	{
		return -ENOMEM;
	}
	/*
	 * Remove all test cases associated with given card. Thus we have only
	 * actual data of the last run.
	 */
	mmc_test_free_result(dni_card);

	dni_test->card = dni_card;

	dni_test->buffer = kzalloc(BUFFER_SIZE, GFP_KERNEL);

	if (dni_test->buffer) {
		mutex_lock(&mmc_test_lock);
		mmc_test_run(dni_test, 2);
		mutex_unlock(&mmc_test_lock);
	}

	
	kfree(dni_test->buffer);
	kfree(dni_test);


	return 0;
}
EXPORT_SYMBOL(mmc_dni_write);

static struct mmc_card *dni_card;
int mmc_dni_write_for_proc(void)
{
	struct mmc_test_card *dni_test;

	dni_test = kzalloc(sizeof(struct mmc_test_card), GFP_KERNEL);
	if (!dni_test)
	{
		return -ENOMEM;
	}
	/*
	 * Remove all test cases associated with given card. Thus we have only
	 * actual data of the last run.
	 */
	mmc_test_free_result(dni_card);

	dni_test->card = dni_card;

	dni_test->buffer = kzalloc(BUFFER_SIZE, GFP_KERNEL);

	if (dni_test->buffer) {
		mutex_lock(&mmc_test_lock);
		mmc_test_run(dni_test, 5);
		mutex_unlock(&mmc_test_lock);
	}

	kfree(dni_test->buffer);
	kfree(dni_test);

	return 0;
}
EXPORT_SYMBOL(mmc_dni_write_for_proc);

static struct mmc_card *dni_card;
int mmc_dni_read(void)
{
	struct mmc_test_card *dni_test;

	dni_test = kzalloc(sizeof(struct mmc_test_card), GFP_KERNEL);
	if (!dni_test)
	{
		return -ENOMEM;
	}
	/*
	 * Remove all test cases associated with given card. Thus we have only
	 * actual data of the last run.
	 */
	mmc_test_free_result(dni_card);

	dni_test->card = dni_card;

	dni_test->buffer = kzalloc(BUFFER_SIZE, GFP_KERNEL);

	if (dni_test->buffer) {
		mutex_lock(&mmc_test_lock);
		mmc_test_run(dni_test, 3);
		mutex_unlock(&mmc_test_lock);
	}

	
	kfree(dni_test->buffer);
	kfree(dni_test);


	return 0;
}
EXPORT_SYMBOL(mmc_dni_read);

static struct mmc_card *dni_card;
int mmc_dni_read_for_proc(void)
{
	struct mmc_test_card *dni_test;

	dni_test = kzalloc(sizeof(struct mmc_test_card), GFP_KERNEL);
	if (!dni_test)
	{
		return -ENOMEM;
	}
	/*
	 * Remove all test cases associated with given card. Thus we have only
	 * actual data of the last run.
	 */
	mmc_test_free_result(dni_card);

	dni_test->card = dni_card;

	dni_test->buffer = kzalloc(BUFFER_SIZE, GFP_KERNEL);

	if (dni_test->buffer) {
		mutex_lock(&mmc_test_lock);
		mmc_test_run(dni_test, 6);
		mutex_unlock(&mmc_test_lock);
	}

	kfree(dni_test->buffer);
	kfree(dni_test);

	return 0;
}
EXPORT_SYMBOL(mmc_dni_read_for_proc);

static struct mmc_card *dni_card;
int mmc_dni_erase(void)
{
	struct mmc_test_card *dni_test;

	dni_test = kzalloc(sizeof(struct mmc_test_card), GFP_KERNEL);
	if (!dni_test)
	{
		return -ENOMEM;
	}
	/*
	 * Remove all test cases associated with given card. Thus we have only
	 * actual data of the last run.
	 */
	mmc_test_free_result(dni_card);

	dni_test->card = dni_card;

	dni_test->buffer = kzalloc(BUFFER_SIZE, GFP_KERNEL);

	if (dni_test->buffer) {
		mutex_lock(&mmc_test_lock);
		mmc_test_run(dni_test, 1);
		mutex_unlock(&mmc_test_lock);
	}

	
	kfree(dni_test->buffer);
	kfree(dni_test);


	return 0;
}
EXPORT_SYMBOL(mmc_dni_erase);

/*the boot partition number will be saved in part_no */
static struct mmc_card *dni_card;
int mmc_dni_art_read_boot_part(char *part_no)
{
	struct mmc_test_card *dni_test;

	dni_test = kzalloc(sizeof(struct mmc_test_card), GFP_KERNEL);
	if (!dni_test)
	{
		return -ENOMEM;
	}
	/*
	 * Remove all test cases associated with given card. Thus we have only
	 * actual data of the last run.
	 */
	mmc_test_free_result(dni_card);

	dni_test->card = dni_card;

	dni_test->buffer = kzalloc(BUFFER_SIZE, GFP_KERNEL);

	if (dni_test->buffer) {
		mutex_lock(&mmc_test_lock);
		mmc_test_run(dni_test, 4);
		mutex_unlock(&mmc_test_lock);
	}

	strncpy(part_no, dni_test->buffer + BOARD_DATA_BOOT_PARTITION_OFFSET, BOARD_DATA_BOOT_PARTITION_LENGTH);

	if (strncmp(part_no, DEFAULT_BOOT_PARTITON1, BOARD_DATA_BOOT_PARTITION_LENGTH) && strncmp(part_no, DEFAULT_BOOT_PARTITON2, BOARD_DATA_BOOT_PARTITION_LENGTH)) {
		/* if the part_no got from art is not equal to neither "01" nor "01", then reset boot paritition to part#1("01") */
		strncpy(part_no, DEFAULT_BOOT_PARTITON1, BOARD_DATA_BOOT_PARTITION_LENGTH);
		printk("mmc_art_verify_read failed. reset rootfs part to #%s\n", part_no);
	}
		printk("%s: rootfs part is #%s\n", __func__, part_no);
	
	kfree(dni_test->buffer);
	kfree(dni_test);


	return 0;
}
EXPORT_SYMBOL(mmc_dni_art_read_boot_part);


static ssize_t mtf_test_write(struct file *file, const char __user *buf,
	size_t count, loff_t *pos)
{
	struct seq_file *sf = (struct seq_file *)file->private_data;
	struct mmc_card *card = (struct mmc_card *)sf->private;
	struct mmc_test_card *test;
	long testcase;
	int ret;

	ret = kstrtol_from_user(buf, count, 10, &testcase);
	if (ret)
		return ret;

	test = kzalloc(sizeof(struct mmc_test_card), GFP_KERNEL);
	if (!test)
		return -ENOMEM;

	/*
	 * Remove all test cases associated with given card. Thus we have only
	 * actual data of the last run.
	 */
	mmc_test_free_result(card);

	test->card = card;

	test->buffer = kzalloc(BUFFER_SIZE, GFP_KERNEL);
#ifdef CONFIG_HIGHMEM
	test->highmem = alloc_pages(GFP_KERNEL | __GFP_HIGHMEM, BUFFER_ORDER);
#endif

#ifdef CONFIG_HIGHMEM
	if (test->buffer && test->highmem) {
#else
	if (test->buffer) {
#endif
		mutex_lock(&mmc_test_lock);
		mmc_test_run(test, testcase);
		mutex_unlock(&mmc_test_lock);
	}

#ifdef CONFIG_HIGHMEM
	__free_pages(test->highmem, BUFFER_ORDER);
#endif
	
	kfree(test->buffer);
	kfree(test);

	return count;
}


static const struct file_operations mmc_test_fops_test = {
	.open		= mtf_test_open,
	.read		= seq_read,
	.write		= mtf_test_write,
	.llseek		= seq_lseek,
	.release	= single_release,
};

static int mtf_testlist_show(struct seq_file *sf, void *data)
{
	int i;

	mutex_lock(&mmc_test_lock);

	for (i = 0; i < ARRAY_SIZE(mmc_test_cases); i++)
		seq_printf(sf, "%d:\t%s\n", i+1, mmc_test_cases[i].name);

	mutex_unlock(&mmc_test_lock);

	return 0;
}

static int mtf_testlist_open(struct inode *inode, struct file *file)
{
	return single_open(file, mtf_testlist_show, inode->i_private);
}

static const struct file_operations mmc_test_fops_testlist = {
	.open		= mtf_testlist_open,
	.read		= seq_read,
	.llseek		= seq_lseek,
	.release	= single_release,
};

static void mmc_test_free_dbgfs_file(struct mmc_card *card)
{
	struct mmc_test_dbgfs_file *df, *dfs;

	mutex_lock(&mmc_test_lock);

	list_for_each_entry_safe(df, dfs, &mmc_test_file_test, link) {
		if (card && df->card != card)
			continue;
		debugfs_remove(df->file);
		list_del(&df->link);
		kfree(df);
	}

	mutex_unlock(&mmc_test_lock);
}

static int __mmc_test_register_dbgfs_file(struct mmc_card *card,
	const char *name, umode_t mode, const struct file_operations *fops)
{
	struct dentry *file = NULL;
	struct mmc_test_dbgfs_file *df;

	if (card->debugfs_root)
		file = debugfs_create_file(name, mode, card->debugfs_root,
			card, fops);

	if (IS_ERR_OR_NULL(file)) {
		dev_err(&card->dev,
			"Can't create %s. Perhaps debugfs is disabled.\n",
			name);
		return -ENODEV;
	}

	df = kmalloc(sizeof(struct mmc_test_dbgfs_file), GFP_KERNEL);
	if (!df) {
		debugfs_remove(file);
		dev_err(&card->dev,
			"Can't allocate memory for internal usage.\n");
		return -ENOMEM;
	}

	df->card = card;
	df->file = file;

	list_add(&df->link, &mmc_test_file_test);
	return 0;
}

static int mmc_test_register_dbgfs_file(struct mmc_card *card)
{
	int ret;

	mutex_lock(&mmc_test_lock);

	ret = __mmc_test_register_dbgfs_file(card, "test", S_IWUSR | S_IRUGO,
		&mmc_test_fops_test);
	if (ret)
		goto err;

	ret = __mmc_test_register_dbgfs_file(card, "testlist", S_IRUGO,
		&mmc_test_fops_testlist);
	if (ret)
		goto err;

err:
	mutex_unlock(&mmc_test_lock);

	return ret;
}

static int mmc_test_probe(struct mmc_card *card)
{
	int ret;

	if (!mmc_card_mmc(card) && !mmc_card_sd(card))
		return -ENODEV;

	dni_card = card;
	ret = mmc_test_register_dbgfs_file(card);
	if (ret)
		return ret;

	dev_info(&card->dev, "Card claimed for testing.\n");

	return 0;
}

#define PANIC_MSG_LEN 65535
static int append_to_buff(char *buff, int length)
{
	int init_ignore_logs = 1, have_start = 0, have_end = 0, found_panic_log = 0;
	int i = 0, need_len = 0, start = 0, ignored = 0;

       	for(i = 0; i < length; i++){
               	if (buff[i] != 'I' || buff[i + 1] != 'n') continue;
		if (!strncmp("Internal error:", &buff[i], strlen("Internal error:") - 1)) {
			if(i > 512) start = i - 512;
			buf_length = 2;
			have_start = 1;
			break;
		}
       	}

        for(i = start; i < length; i++){
               	if (buff[i] != 's' || buff[i + 1] != 't') continue;
		if (!strncmp("stack limit =", &buff[i], strlen("stack limit =") - 1)) {
			have_end = 1;
			break;
		}
	}
	if (have_start == 0 || have_end == 0) return found_panic_log;
	found_panic_log = 1;
	need_len = length - start;
	
	for(i = 0; i < need_len; i++) {
		if (init_ignore_logs && buff[start + i] == 'M' && buff[start + i + 1] == 'o') {
			if (!strncmp("Modules linked", &buff[start + i], strlen("Modules linked") - 1)) {
				init_ignore_logs = 0;
				ignored = 0;
			}
		}
		if (buff[start + i] == '<' && buff[start + i + 2] == '>') {
			ignored = 0;
			if (init_ignore_logs) {
				if (buff[start + i + 1] > '3' && buff[start + i + 1] < '8') 
					ignored = 1;
			} else {
				if (buff[start + i + 1] > '4' && buff[start + i + 1] < '8') 
					ignored = 1;
			}
		}
		if(ignored) continue;
		if(buf_length > 16380) break;
		dni_panic_buf[buf_length++] = buff[start + i];
	}
	return found_panic_log;
}

extern int log_buf_copy(char *dest, int idx, int size);
char emmc_log_buff[PANIC_MSG_LEN+1];
static void write_console_log_to_emmc(void)
{
	if(sysctl_save_panic_data_enable == 0)
		return NOTIFY_DONE;

	char fail_msg[] = "Crashdump did not found panic log...\n";
	int i = 0, count = 0, idx = 0, found_panic_log = 0;

	for(i = 0; i < 100; i++) {
		count = log_buf_copy(emmc_log_buff, idx, PANIC_MSG_LEN); 
		found_panic_log = append_to_buff(emmc_log_buff, count);
		if (count <= 0) break;
		idx = idx + count;
		if (found_panic_log) break;
	}
	if(!found_panic_log) {
		printk("%s", fail_msg);
		memcpy(dni_panic_buf + 2, fail_msg, sizeof(fail_msg));
	}

	mmc_dni_read();

	if(strncmp(dni_panic_flag,"15",2)==0)
	{	
		printk("console_panic_event_________partition is full data, and erase it\n");
		mmc_dni_erase();
		devaddr_flag=1;
		dni_panic_flag[0] = '1';
		dni_panic_flag[1] = '\0';
	}
	else if(strcmp(dni_panic_flag,"0"))
	{
		printk("console_panic_event_________write %d times\n",devaddr_flag);
		sprintf(dni_panic_flag,"%d",devaddr_flag);
	}
	else if(strcmp(dni_panic_flag,"0")==0)
	{
		devaddr_flag=1;
		dni_panic_flag[0] = '1';
	}

	dni_panic_buf[0] = dni_panic_flag[0];
	if(dni_panic_flag[1] != '\0')
		dni_panic_buf[1] = dni_panic_flag[1];
	else
		dni_panic_buf[1] = ' ';

	mmc_dni_write();

	return NOTIFY_DONE;
}

int console_panic_to_mmc(void)
{
	if(sysctl_save_panic_data_enable == 0)
		return 0;

	printk("@@@@@@@@@ DNI Kernel panic @@@@@@@@@@\n");
	write_console_log_to_emmc();

	memset(dni_panic_buf, 0x00, sizeof(dni_panic_buf));
	reboot_reason_flags = reboot_reason_flags | (0x1 << 4);
	sprintf(dni_panic_buf, "0x%x", reboot_reason_flags);
	mmc_dni_write_for_proc();
	
	return 0;
}
EXPORT_SYMBOL(console_panic_to_mmc);

static int console_panic_event(struct notifier_block *blk, unsigned long event, void *ptr)
{
	if(sysctl_save_panic_data_enable == 0)
		return NOTIFY_DONE;
	printk("@@@@@@@@@ DNI Kernel panic @@@@@@@@@@\n");
	write_console_log_to_emmc();

	memset(dni_panic_buf, 0x00, sizeof(dni_panic_buf));
	reboot_reason_flags = reboot_reason_flags | (0x1 << 4);
	sprintf(dni_panic_buf, "0x%x", reboot_reason_flags);
	mmc_dni_write_for_proc();
 	
 	return NOTIFY_DONE;
}

static struct notifier_block console_panic_block = {
	.notifier_call = console_panic_event,
	.next = NULL,
	.priority = INT_MAX /* try to do it first */
};

static int dni_oom_handler(struct notifier_block *self, unsigned long val, void *data)
{
	if(sysctl_save_panic_data_enable == 0)
		return NOTIFY_DONE;
	memset(dni_panic_buf, 0x00, sizeof(dni_panic_buf));
	printk("@@@@@@@@@ DNI Kernel oom @@@@@@@@@@\n");
	reboot_reason_flags = reboot_reason_flags | (0x1 << 2);
	sprintf(dni_panic_buf, "0x%x", reboot_reason_flags);
	mmc_dni_write_for_proc();
	//write_console_log_to_emmc();

	return NOTIFY_DONE;
}

static struct notifier_block dni_oom_notifier = {
	.notifier_call = dni_oom_handler,
};

static int dni_oops_handler(struct notifier_block *self, unsigned long val, void *data)
{
	if(sysctl_save_panic_data_enable == 0)
		return NOTIFY_DONE;
	memset(dni_panic_buf, 0x00, sizeof(dni_panic_buf));
	if(val == DIE_OOPS) {
		printk("@@@@@@@@@ DNI Kernel oops @@@@@@@@@@\n");
		reboot_reason_flags = reboot_reason_flags | (0x1 << 3);
		sprintf(dni_panic_buf, "0x%x", reboot_reason_flags);
		//mmc_dni_write_for_proc();
		//write_console_log_to_emmc();
	}

	return NOTIFY_DONE;
}

static struct notifier_block dni_oops_notifier = {
	.notifier_call = dni_oops_handler,
};

static int dni_reboot_handler(struct notifier_block *self, unsigned long val, void *data)
{
	switch(val) {
		case SYS_HALT:
			printk("@@@@@@@@@ DNI Kernel halt @@@@@@@@@@\n");
			break;

		case SYS_RESTART:
			printk("@@@@@@@@@ DNI Kernel restart @@@@@@@@@@\n");
			break;

		case SYS_POWER_OFF:
			printk("@@@@@@@@@ DNI Kernel power off @@@@@@@@@@\n");
			break;
	}

	return NOTIFY_DONE;
}

static struct notifier_block dni_reboot_notifier = {
	.notifier_call = dni_reboot_handler,
};

void dni_watchdog_handler(void)
{
	if(sysctl_save_panic_data_enable == 0)
		return NOTIFY_DONE;
	memset(dni_panic_buf, 0x00, sizeof(dni_panic_buf));
	printk("@@@@@@@@@ DNI Kernel watchdog reboot @@@@@@@@@@\n");
	reboot_reason_flags = reboot_reason_flags | (0x1 << 5);
	sprintf(dni_panic_buf, "0x%x", reboot_reason_flags);
	mmc_dni_write_for_proc();
	//write_console_log_to_emmc();
}
EXPORT_SYMBOL(dni_watchdog_handler);

static int reboot_reason_read(struct file *file, char __user *buf, size_t count, loff_t *ppos)
{
	char buffer[8];
	int len = 4;

	mmc_dni_read_for_proc();
	reboot_reason_flags = simple_strtoul(dni_panic_flag, NULL, 16);
	len = snprintf(buffer, sizeof(buffer), "0x%x", reboot_reason_flags);

	reboot_reason_flags = 0x00;
	sprintf(dni_panic_buf, "0x%x", reboot_reason_flags);
	mmc_dni_write_for_proc();

	return simple_read_from_buffer(buf, count, ppos, buffer, len);
}

static int reboot_reason_write(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
	unsigned long tmp_bits = 0;

	if(sysctl_save_panic_data_enable == 0)
		return count;
	tmp_bits = simple_strtoul(buf, NULL, 16);
	reboot_reason_flags = reboot_reason_flags | (0x1 << tmp_bits);
	sprintf(dni_panic_buf, "0x%x\n", reboot_reason_flags);
	mmc_dni_write_for_proc();
	
	return count;
}

static const struct file_operations proc_reboot_reason_operations = {
	.read       = reboot_reason_read,
	.write      = reboot_reason_write,
};

static void reboot_reason_proc_init(void)
{
	struct proc_dir_entry *reboot_reason;

	reboot_reason = proc_create("reboot_reason", 0666, NULL, &proc_reboot_reason_operations);
}

static void mmc_test_remove(struct mmc_card *card)
{
	mmc_test_free_result(card);
	mmc_test_free_dbgfs_file(card);
}

static void mmc_test_shutdown(struct mmc_card *card)
{
}

static struct mmc_driver mmc_driver = {
	.drv		= {
		.name	= "mmc_test",
	},
	.probe		= mmc_test_probe,
	.remove		= mmc_test_remove,
	.shutdown	= mmc_test_shutdown,
};

static int __init mmc_test_init(void)
{
	if(strcmp(flash_type_name,"EMMC") != 0)
		return -1;

	register_reboot_notifier(&dni_reboot_notifier);
	register_die_notifier(&dni_oops_notifier);
	register_oom_notifier(&dni_oom_notifier);
	//atomic_notifier_chain_register(&panic_notifier_list, &console_panic_block);
	reboot_reason_proc_init();
	return mmc_register_driver(&mmc_driver);
}

static void __exit mmc_test_exit(void)
{
	if(strcmp(flash_type_name,"EMMC") != 0)
		return -1;

	/* Clear stalled data if card is still plugged */
	mmc_test_free_result(NULL);
	mmc_test_free_dbgfs_file(NULL);

	mmc_unregister_driver(&mmc_driver);
}

module_init(mmc_test_init);
module_exit(mmc_test_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Multimedia Card (MMC) host test driver");
MODULE_AUTHOR("Pierre Ossman");
