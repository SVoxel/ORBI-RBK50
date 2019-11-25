/* vi: set sw=4 ts=4: */
/*
 * Mini syslogd implementation for busybox
 *
 * Copyright (C) 1999-2004 by Erik Andersen <andersen@codepoet.org>
 *
 * Copyright (C) 2000 by Karl M. Hegbloom <karlheg@debian.org>
 *
 * "circular buffer" Copyright (C) 2001 by Gennady Feldman <gfeldman@gena01.com>
 *
 * Maintainer: Gennady Feldman <gfeldman@gena01.com> as of Mar 12, 2001
 *
 * Licensed under GPLv2 or later, see file LICENSE in this source tree.
 */

//usage:#define syslogd_trivial_usage
//usage:       "[OPTIONS]"
//usage:#define syslogd_full_usage "\n\n"
//usage:       "System logging utility\n"
//usage:	IF_NOT_FEATURE_SYSLOGD_CFG(
//usage:       "(this version of syslogd ignores /etc/syslog.conf)\n"
//usage:	)
//usage:     "\n	-n		Run in foreground"
//usage:	IF_FEATURE_REMOTE_LOG(
//usage:     "\n	-R HOST[:PORT]	Log to HOST:PORT (default PORT:514)"
//usage:     "\n	-L		Log locally and via network (default is network only if -R)"
//usage:	)
//usage:	IF_FEATURE_TIMEZONE_LOG(
//usage:     "\n	-T TIMEZONE	Set time zone"
//usage:	)
//usage:	IF_FEATURE_VENDOR_FORMAT_LOG(
//usage:     "\n	-V VENDOR	Set specifict Vendor required format message in log,like NETGEAR"
//usage:     "\n	-c LOGCATEGORY	Separate different log message"
//usage:	)
//usage:	IF_FEATURE_IPC_SYSLOG(
/* NB: -Csize shouldn't have space (because size is optional) */
//usage:     "\n	-C[size_kb]	Log to shared mem buffer (use logread to read it)"
//usage:	)
//usage:	IF_FEATURE_KMSG_SYSLOG(
//usage:     "\n	-K		Log to kernel printk buffer (use dmesg to read it)"
//usage:	)
//usage:     "\n	-O FILE		Log to FILE (default:/var/log/messages, stdout if -)"
//usage:	IF_FEATURE_ROTATE_LOGFILE(
//usage:     "\n	-s SIZE		Max size (KB) before rotation (default:200KB, 0=off)"
//usage:     "\n	-b N		N rotated logs to keep (default:1, max=99, 0=purge)"
//usage:	)
//usage:     "\n	-l N		Log only messages more urgent than prio N (1-8)"
//usage:     "\n	-S		Smaller output"
//usage:	IF_FEATURE_SYSLOGD_DUP(
//usage:     "\n	-D		Drop duplicates"
//usage:	)
//usage:	IF_FEATURE_SYSLOGD_CFG(
//usage:     "\n	-f FILE		Use FILE as config (default:/etc/syslog.conf)"
//usage:	)
/* //usage:  "\n	-m MIN		Minutes between MARK lines (default:20, 0=off)" */
//usage:
//usage:#define syslogd_example_usage
//usage:       "$ syslogd -R masterlog:514\n"
//usage:       "$ syslogd -R 192.168.1.1:601\n"

/*
 * Done in syslogd_and_logger.c:
#include "libbb.h"
#define SYSLOG_NAMES
#define SYSLOG_NAMES_CONST
#include <syslog.h>
*/
#ifndef _PATH_LOG
#define _PATH_LOG	"/dev/log"
#endif

#include <sys/un.h>
#include <sys/uio.h>
#include <sys/time.h>
#include <time.h>

#if ENABLE_FEATURE_REMOTE_LOG
#include <netinet/in.h>
#endif

#if ENABLE_FEATURE_IPC_SYSLOG
#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/shm.h>
#endif

#if ENABLE_FEATURE_VENDOR_FORMAT_LOG
#include <sys/sysinfo.h>
#endif

#define BLOCK_SITE_LOG "/var/log/block-site-messages"
#define DEBUG 0

/* MARK code is not very useful, is bloat, and broken:
 * can deadlock if alarmed to make MARK while writing to IPC buffer
 * (semaphores are down but do_mark routine tries to down them again) */
#undef SYSLOGD_MARK

/* Write locking does not seem to be useful either */
#undef SYSLOGD_WRLOCK

enum {
	MAX_READ = CONFIG_FEATURE_SYSLOGD_READ_BUFFER_SIZE,
	DNS_WAIT_SEC = 2 * 60,
};

/* Semaphore operation structures */
struct shbuf_ds {
	int32_t size;   /* size of data - 1 */
	int32_t tail;   /* end of message list */
	char data[1];   /* data/messages */
};

#if ENABLE_FEATURE_REMOTE_LOG
typedef struct {
	int remoteFD;
	unsigned last_dns_resolve;
	len_and_sockaddr *remoteAddr;
	const char *remoteHostname;
} remoteHost_t;
#endif

#if ENABLE_FEATURE_VENDOR_FORMAT_LOG
static char vendor[32] = "NETGEAR";		/*the default format according to NETGEAR SPEC*/
static unsigned int logcy = (0x01 << 11) - 1;
static int regenerate_log_flag = 0;
#endif

typedef struct logFile_t {
	const char *path;
	int fd;
	time_t last_log_time;
#if ENABLE_FEATURE_ROTATE_LOGFILE
#define LOG_DEL_NUM 120
	unsigned size;
	uint8_t isRegular;
#endif
} logFile_t;

#if ENABLE_FEATURE_SYSLOGD_CFG
typedef struct logRule_t {
	uint8_t enabled_facility_priomap[LOG_NFACILITIES];
	struct logFile_t *file;
	struct logRule_t *next;
} logRule_t;
#endif

/* Allows us to have smaller initializer. Ugly. */
#define GLOBALS \
	logFile_t logFile;                      \
	/* interval between marks in seconds */ \
	/*int markInterval;*/                   \
	/* level of messages to be logged */    \
	int logLevel;                           \
IF_FEATURE_ROTATE_LOGFILE( \
	/* max size of file before rotation */  \
	unsigned logFileSize;                   \
	/* number of rotated message files */   \
	unsigned logFileRotate;                 \
) \
IF_FEATURE_IPC_SYSLOG( \
	int shmid; /* ipc shared memory id */   \
	int s_semid; /* ipc semaphore id */     \
	int shm_size;                           \
	struct sembuf SMwup[1];                 \
	struct sembuf SMwdn[3];                 \
) \
IF_FEATURE_SYSLOGD_CFG( \
	logRule_t *log_rules; \
) \
IF_FEATURE_KMSG_SYSLOG( \
	int kmsgfd; \
	int primask; \
)

struct init_globals {
	GLOBALS
};

struct globals {
	GLOBALS

#if ENABLE_FEATURE_REMOTE_LOG
	llist_t *remoteHosts;
#endif
#if ENABLE_FEATURE_IPC_SYSLOG
	struct shbuf_ds *shbuf;
#endif
	/* localhost's name. We print only first 64 chars */
	char *hostname;

	/* We recv into recvbuf... */
	char recvbuf[MAX_READ * (1 + ENABLE_FEATURE_SYSLOGD_DUP)];
	/* ...then copy to parsebuf, escaping control chars */
	/* (can grow x2 max) */
	char parsebuf[MAX_READ*2];
	/* ...then sprintf into printbuf, adding timestamp (15 chars),
	 * host (64), fac.prio (20) to the message */
	/* (growth by: 15 + 64 + 20 + delims = ~110) */
	char printbuf[MAX_READ*2 + 128];
};

static const struct init_globals init_data = {
	.logFile = {
		.path = "/var/log/messages",
		.fd = -1,
	},
#ifdef SYSLOGD_MARK
	.markInterval = 20 * 60,
#endif
	.logLevel = 8,
#if ENABLE_FEATURE_ROTATE_LOGFILE
	.logFileSize = 50 * 1024,
	.logFileRotate = 1,
#endif
#if ENABLE_FEATURE_IPC_SYSLOG
	.shmid = -1,
	.s_semid = -1,
	.shm_size = ((CONFIG_FEATURE_IPC_SYSLOG_BUFFER_SIZE)*1024), /* default shm size */
	.SMwup = { {1, -1, IPC_NOWAIT} },
	.SMwdn = { {0, 0}, {1, 0}, {1, +1} },
#endif
};

#define G (*ptr_to_globals)
#define INIT_G() do { \
	SET_PTR_TO_GLOBALS(memcpy(xzalloc(sizeof(G)), &init_data, sizeof(init_data))); \
} while (0)


/* Options */
enum {
	OPTBIT_mark = 0, // -m
	OPTBIT_nofork, // -n
	OPTBIT_outfile, // -O
	OPTBIT_loglevel, // -l
	OPTBIT_small, // -S
	IF_FEATURE_ROTATE_LOGFILE(OPTBIT_filesize   ,)	// -s
	IF_FEATURE_ROTATE_LOGFILE(OPTBIT_rotatecnt  ,)	// -b
	IF_FEATURE_REMOTE_LOG(    OPTBIT_remotelog  ,)	// -R
	IF_FEATURE_REMOTE_LOG(    OPTBIT_locallog   ,)	// -L
	IF_FEATURE_TIMEZONE_LOG(  OPTBIT_timezone   ,)	// -T
	IF_FEATURE_VENDOR_FORMAT_LOG(  OPTBIT_vendor,)	// -V
	IF_FEATURE_VENDOR_FORMAT_LOG(  OPTBIT_logcategory,)	// -c
	IF_FEATURE_IPC_SYSLOG(    OPTBIT_circularlog,)	// -C
	IF_FEATURE_SYSLOGD_DUP(   OPTBIT_dup        ,)	// -D
	IF_FEATURE_SYSLOGD_CFG(   OPTBIT_cfg        ,)	// -f
	IF_FEATURE_KMSG_SYSLOG(   OPTBIT_kmsg       ,)	// -K

	OPT_mark        = 1 << OPTBIT_mark    ,
	OPT_nofork      = 1 << OPTBIT_nofork  ,
	OPT_outfile     = 1 << OPTBIT_outfile ,
	OPT_loglevel    = 1 << OPTBIT_loglevel,
	OPT_small       = 1 << OPTBIT_small   ,
	OPT_filesize    = IF_FEATURE_ROTATE_LOGFILE(	(1 << OPTBIT_filesize   )) + 0,
	OPT_rotatecnt   = IF_FEATURE_ROTATE_LOGFILE(	(1 << OPTBIT_rotatecnt  )) + 0,
	OPT_remotelog   = IF_FEATURE_REMOTE_LOG(    	(1 << OPTBIT_remotelog  )) + 0,
	OPT_locallog    = IF_FEATURE_REMOTE_LOG(    	(1 << OPTBIT_locallog   )) + 0,
	OPT_timezone    = IF_FEATURE_TIMEZONE_LOG(  	(1 << OPTBIT_timezone   )) + 0,
	OPT_vendor      = IF_FEATURE_VENDOR_FORMAT_LOG(	(1 << OPTBIT_vendor     )) + 0,
	OPT_logcategory = IF_FEATURE_VENDOR_FORMAT_LOG(	(1 << OPTBIT_logcategory)) + 0,
	OPT_circularlog = IF_FEATURE_IPC_SYSLOG(    	(1 << OPTBIT_circularlog)) + 0,
	OPT_dup         = IF_FEATURE_SYSLOGD_DUP(   	(1 << OPTBIT_dup        )) + 0,
	OPT_cfg         = IF_FEATURE_SYSLOGD_CFG(   	(1 << OPTBIT_cfg        )) + 0,
	OPT_kmsg        = IF_FEATURE_KMSG_SYSLOG(   	(1 << OPTBIT_kmsg       )) + 0,
};
#define OPTION_STR "m:nO:l:S" \
	IF_FEATURE_ROTATE_LOGFILE(      "s:" ) \
	IF_FEATURE_ROTATE_LOGFILE(      "b:" ) \
	IF_FEATURE_REMOTE_LOG(          "R:" ) \
	IF_FEATURE_REMOTE_LOG(          "L"  ) \
	IF_FEATURE_TIMEZONE_LOG(        "T:" ) \
	IF_FEATURE_VENDOR_FORMAT_LOG(   "V:" ) \
	IF_FEATURE_VENDOR_FORMAT_LOG(   "c:" ) \
	IF_FEATURE_IPC_SYSLOG(          "C::") \
	IF_FEATURE_SYSLOGD_DUP(         "D"  ) \
	IF_FEATURE_SYSLOGD_CFG(         "f:" ) \
	IF_FEATURE_KMSG_SYSLOG(         "K"  )
#define OPTION_DECL *opt_m, *opt_l \
	IF_FEATURE_ROTATE_LOGFILE(      ,*opt_s) \
	IF_FEATURE_ROTATE_LOGFILE(      ,*opt_b) \
	IF_FEATURE_TIMEZONE_LOG(        ,*opt_T = NULL) \
	IF_FEATURE_VENDOR_FORMAT_LOG(   ,*opt_V = NULL) \
	IF_FEATURE_VENDOR_FORMAT_LOG(   ,*opt_c = NULL) \
	IF_FEATURE_IPC_SYSLOG(          ,*opt_C = NULL) \
	IF_FEATURE_SYSLOGD_CFG(         ,*opt_f = NULL)
#define OPTION_PARAM &opt_m, &(G.logFile.path), &opt_l \
	IF_FEATURE_ROTATE_LOGFILE(      ,&opt_s) \
	IF_FEATURE_ROTATE_LOGFILE(      ,&opt_b) \
	IF_FEATURE_REMOTE_LOG(          ,&remoteAddrList) \
	IF_FEATURE_TIMEZONE_LOG(        ,&opt_T) \
	IF_FEATURE_VENDOR_FORMAT_LOG(   ,&opt_V) \
	IF_FEATURE_VENDOR_FORMAT_LOG(   ,&opt_c) \
	IF_FEATURE_IPC_SYSLOG(          ,&opt_C) \
	IF_FEATURE_SYSLOGD_CFG(         ,&opt_f)


#if ENABLE_FEATURE_SYSLOGD_CFG
static const CODE* find_by_name(char *name, const CODE* c_set)
{
	for (; c_set->c_name; c_set++) {
		if (strcmp(name, c_set->c_name) == 0)
			return c_set;
	}
	return NULL;
}
#endif
static const CODE* find_by_val(int val, const CODE* c_set)
{
	for (; c_set->c_name; c_set++) {
		if (c_set->c_val == val)
			return c_set;
	}
	return NULL;
}

#if ENABLE_FEATURE_SYSLOGD_CFG
static void parse_syslogdcfg(const char *file)
{
	char *t;
	logRule_t **pp_rule;
	/* tok[0] set of selectors */
	/* tok[1] file name */
	/* tok[2] has to be NULL */
	char *tok[3];
	parser_t *parser;

	parser = config_open2(file ? file : "/etc/syslog.conf",
				file ? xfopen_for_read : fopen_for_read);
	if (!parser)
		/* didn't find default /etc/syslog.conf */
		/* proceed as if we built busybox without config support */
		return;

	/* use ptr to ptr to avoid checking whether head was initialized */
	pp_rule = &G.log_rules;
	/* iterate through lines of config, skipping comments */
	while (config_read(parser, tok, 3, 2, "# \t", PARSE_NORMAL | PARSE_MIN_DIE)) {
		char *cur_selector;
		logRule_t *cur_rule;

		/* unexpected trailing token? */
		if (tok[2])
			goto cfgerr;

		cur_rule = *pp_rule = xzalloc(sizeof(*cur_rule));

		cur_selector = tok[0];
		/* iterate through selectors: "kern.info;kern.!err;..." */
		do {
			const CODE *code;
			char *next_selector;
			uint8_t negated_prio; /* "kern.!err" */
			uint8_t single_prio;  /* "kern.=err" */
			uint32_t facmap; /* bitmap of enabled facilities */
			uint8_t primap;  /* bitmap of enabled priorities */
			unsigned i;

			next_selector = strchr(cur_selector, ';');
			if (next_selector)
				*next_selector++ = '\0';

			t = strchr(cur_selector, '.');
			if (!t)
				goto cfgerr;
			*t++ = '\0'; /* separate facility from priority */

			negated_prio = 0;
			single_prio = 0;
			if (*t == '!') {
				negated_prio = 1;
				++t;
			}
			if (*t == '=') {
				single_prio = 1;
				++t;
			}

			/* parse priority */
			if (*t == '*')
				primap = 0xff; /* all 8 log levels enabled */
			else {
				uint8_t priority;
				code = find_by_name(t, prioritynames);
				if (!code)
					goto cfgerr;
				primap = 0;
				priority = code->c_val;
				if (priority == INTERNAL_NOPRI) {
					/* ensure we take "enabled_facility_priomap[fac] &= 0" branch below */
					negated_prio = 1;
				} else {
					priority = 1 << priority;
					do {
						primap |= priority;
						if (single_prio)
							break;
						priority >>= 1;
					} while (priority);
					if (negated_prio)
						primap = ~primap;
				}
			}

			/* parse facility */
			if (*cur_selector == '*')
				facmap = (1<<LOG_NFACILITIES) - 1;
			else {
				char *next_facility;
				facmap = 0;
				t = cur_selector;
				/* iterate through facilities: "kern,daemon.<priospec>" */
				do {
					next_facility = strchr(t, ',');
					if (next_facility)
						*next_facility++ = '\0';
					code = find_by_name(t, facilitynames);
					if (!code)
						goto cfgerr;
					/* "mark" is not a real facility, skip it */
					if (code->c_val != INTERNAL_MARK)
						facmap |= 1<<(LOG_FAC(code->c_val));
					t = next_facility;
				} while (t);
			}

			/* merge result with previous selectors */
			for (i = 0; i < LOG_NFACILITIES; ++i) {
				if (!(facmap & (1<<i)))
					continue;
				if (negated_prio)
					cur_rule->enabled_facility_priomap[i] &= primap;
				else
					cur_rule->enabled_facility_priomap[i] |= primap;
			}

			cur_selector = next_selector;
		} while (cur_selector);

		/* check whether current file name was mentioned in previous rules or
		 * as global logfile (G.logFile).
		 */
		if (strcmp(G.logFile.path, tok[1]) == 0) {
			cur_rule->file = &G.logFile;
			goto found;
		}
		/* temporarily use cur_rule as iterator, but *pp_rule still points
		 * to currently processing rule entry.
		 * NOTE: *pp_rule points to the current (and last in the list) rule.
		 */
		for (cur_rule = G.log_rules; cur_rule != *pp_rule; cur_rule = cur_rule->next) {
			if (strcmp(cur_rule->file->path, tok[1]) == 0) {
				/* found - reuse the same file structure */
				(*pp_rule)->file = cur_rule->file;
				cur_rule = *pp_rule;
				goto found;
			}
		}
		cur_rule->file = xzalloc(sizeof(*cur_rule->file));
		cur_rule->file->fd = -1;
		cur_rule->file->path = xstrdup(tok[1]);
 found:
		pp_rule = &cur_rule->next;
	}
	config_close(parser);
	return;

 cfgerr:
	bb_error_msg_and_die("error in '%s' at line %d",
			file ? file : "/etc/syslog.conf",
			parser->lineno);
}
#endif

/* circular buffer variables/structures */
#if ENABLE_FEATURE_IPC_SYSLOG

#if CONFIG_FEATURE_IPC_SYSLOG_BUFFER_SIZE < 4
#error Sorry, you must set the syslogd buffer size to at least 4KB.
#error Please check CONFIG_FEATURE_IPC_SYSLOG_BUFFER_SIZE
#endif

/* our shared key (syslogd.c and logread.c must be in sync) */
enum { KEY_ID = 0x414e4547 }; /* "GENA" */

static void ipcsyslog_cleanup(void)
{
	if (G.shmid != -1) {
		shmdt(G.shbuf);
	}
	if (G.shmid != -1) {
		shmctl(G.shmid, IPC_RMID, NULL);
	}
	if (G.s_semid != -1) {
		semctl(G.s_semid, 0, IPC_RMID, 0);
	}
}

static void ipcsyslog_init(void)
{
	if (DEBUG)
		printf("shmget(%x, %d,...)\n", (int)KEY_ID, G.shm_size);

	G.shmid = shmget(KEY_ID, G.shm_size, IPC_CREAT | 0644);
	if (G.shmid == -1) {
		bb_perror_msg_and_die("shmget");
	}

	G.shbuf = shmat(G.shmid, NULL, 0);
	if (G.shbuf == (void*) -1L) { /* shmat has bizarre error return */
		bb_perror_msg_and_die("shmat");
	}

	memset(G.shbuf, 0, G.shm_size);
	G.shbuf->size = G.shm_size - offsetof(struct shbuf_ds, data) - 1;
	/*G.shbuf->tail = 0;*/

	/* we'll trust the OS to set initial semval to 0 (let's hope) */
	G.s_semid = semget(KEY_ID, 2, IPC_CREAT | IPC_EXCL | 1023);
	if (G.s_semid == -1) {
		if (errno == EEXIST) {
			G.s_semid = semget(KEY_ID, 2, 0);
			if (G.s_semid != -1)
				return;
		}
		bb_perror_msg_and_die("semget");
	}
}

/* Write message to shared mem buffer */
static void log_to_shmem(const char *msg)
{
	int old_tail, new_tail;
	int len;

	if (semop(G.s_semid, G.SMwdn, 3) == -1) {
		bb_perror_msg_and_die("SMwdn");
	}

	/* Circular Buffer Algorithm:
	 * --------------------------
	 * tail == position where to store next syslog message.
	 * tail's max value is (shbuf->size - 1)
	 * Last byte of buffer is never used and remains NUL.
	 */
	len = strlen(msg) + 1; /* length with NUL included */
 again:
	old_tail = G.shbuf->tail;
	new_tail = old_tail + len;
	if (new_tail < G.shbuf->size) {
		/* store message, set new tail */
		memcpy(G.shbuf->data + old_tail, msg, len);
		G.shbuf->tail = new_tail;
	} else {
		/* k == available buffer space ahead of old tail */
		int k = G.shbuf->size - old_tail;
		/* copy what fits to the end of buffer, and repeat */
		memcpy(G.shbuf->data + old_tail, msg, k);
		msg += k;
		len -= k;
		G.shbuf->tail = 0;
		goto again;
	}
	if (semop(G.s_semid, G.SMwup, 1) == -1) {
		bb_perror_msg_and_die("SMwup");
	}
	if (DEBUG)
		printf("tail:%d\n", G.shbuf->tail);
}
#else
static void ipcsyslog_cleanup(void) {}
static void ipcsyslog_init(void) {}
void log_to_shmem(const char *msg);
#endif /* FEATURE_IPC_SYSLOG */

#if ENABLE_FEATURE_KMSG_SYSLOG
static void kmsg_init(void)
{
	G.kmsgfd = xopen("/dev/kmsg", O_WRONLY);

	/*
	 * kernel < 3.5 expects single char printk KERN_* priority prefix,
	 * from 3.5 onwards the full syslog facility/priority format is supported
	 */
	if (get_linux_version_code() < KERNEL_VERSION(3,5,0))
		G.primask = LOG_PRIMASK;
	else
		G.primask = -1;
}

static void kmsg_cleanup(void)
{
	if (ENABLE_FEATURE_CLEAN_UP)
		close(G.kmsgfd);
}

/* Write message to /dev/kmsg */
static void log_to_kmsg(int pri, const char *msg)
{
	/*
	 * kernel < 3.5 expects single char printk KERN_* priority prefix,
	 * from 3.5 onwards the full syslog facility/priority format is supported
	 */
	pri &= G.primask;

	full_write(G.kmsgfd, G.printbuf, sprintf(G.printbuf, "<%d>%s\n", pri, msg));
}
#else
static void kmsg_init(void) {}
static void kmsg_cleanup(void) {}
static void log_to_kmsg(int pri UNUSED_PARAM, const char *msg UNUSED_PARAM) {}
#endif /* FEATURE_KMSG_SYSLOG */

void limit_log_len(char *file,unsigned int maxsize,int num)
{
	FILE *logfp;

	logfp = fopen(file,"r");
	if(logfp == NULL){
		printf("fail to open the file %s\n",file);
		return;
	}
#if ENABLE_FEATURE_ROTATE_LOGFILE
	struct stat statf;
	int isRegular;
	int curSize;

	isRegular = (stat(file, &statf) == 0 && (statf.st_mode & S_IFREG));
	/*bug(mostly harmless),can wrap aroud if file > 4gb*/
	curSize = statf.st_size;

	if(maxsize && isRegular && curSize > maxsize){
		FILE *fp;
		int flag = 0;
		char buff[1024];
		char tmplogfile[256];
		
		sprintf(tmplogfile,"/tmp/log/newlog");
		fp = fopen(tmplogfile,"w");
		if(fp == NULL){
			printf("fail to open the file: %s\n",tmplogfile);
			goto end;
		}

		while(fgets(buff,1024,logfp)){
			if(flag == 1)
				fprintf(fp,"%s",buff);
			else{
				num--;
				if(num <= 0)
					flag = 1;
			}
		}
		fclose(fp);
		fclose(logfp);
		remove(file);
		rename(tmplogfile,file);
		remove(tmplogfile);
		return;
	}

#endif
end:
	fclose(logfp);
	return;
}
/* Print a message to the log file. */
static void log_locally(time_t now, char *msg, logFile_t *log_file)
{
#ifdef SYSLOGD_WRLOCK
	struct flock fl;
#endif
	FILE *fp;
	int len = strlen(msg);

	/* fd can't be 0 (we connect fd 0 to /dev/log socket) */
	/* fd is 1 if "-O -" is in use */
	if (log_file->fd > 1) {
		/* Reopen log files every second. This allows admin
		 * to delete the files and not worry about restarting us.
		 * This costs almost nothing since it happens
		 * _at most_ once a second for each file, and happens
		 * only when each file is actually written.
		 */
		if (!now)
			now = time(NULL);
		if (log_file->last_log_time != now) {
			log_file->last_log_time = now;
			close(log_file->fd);
			goto reopen;
		}
	}
	else if (log_file->fd == 1) {
		/* We are logging to stdout: do nothing */
	}
	else {
		if (LONE_DASH(log_file->path)) {
			log_file->fd = 1;
			/* log_file->isRegular = 0; - already is */
		} else {
 reopen:
			log_file->fd = open(log_file->path, O_WRONLY | O_CREAT
					| O_NOCTTY | O_APPEND | O_NONBLOCK,
					0666);
			if (log_file->fd < 0) {
				/* cannot open logfile? - print to /dev/console then */
				int fd = device_open(DEV_CONSOLE, O_WRONLY | O_NOCTTY | O_NONBLOCK);
				if (fd < 0)
					fd = 2; /* then stderr, dammit */
				full_write(fd, msg, len);
				if (fd != 2)
					close(fd);
				return;
			}
		}
	}
	
	limit_log_len(G.logFile.path,G.logFileSize,LOG_DEL_NUM);

	fp = fopen(G.logFile.path, "a+");
	if (fp == NULL){
		printf("fail to open the file:%s\n",G.logFile.path);
		return;
	}

	fprintf(fp,"%s",msg);
	fclose(fp);

	return;
}

static void parse_fac_prio_20(int pri, char *res20)
{
	const CODE *c_pri, *c_fac;

	c_fac = find_by_val(LOG_FAC(pri) << 3, facilitynames);
	if (c_fac) {
		c_pri = find_by_val(LOG_PRI(pri), prioritynames);
		if (c_pri) {
			snprintf(res20, 20, "%s.%s", c_fac->c_name, c_pri->c_name);
			return;
		}
	}
	snprintf(res20, 20, "<%d>", pri);
}
#if ENABLE_FEATURE_VENDOR_FORMAT_LOG

/*the file save the log information format: timestamp:log*/
#define SYSLOG_FILE "/tmp/log/log_message"
/*DUT get the NTP time first.*/
#define NTP_FTIME "/tmp/log/updated_log"

unsigned int logorgsize = 200 * 1024;
#define LOG_ORG_DEL_NUM 500
extern int update_first_time(void);
extern int generate_log_message(int flag,int info);
static void set_mobile_log(char *src, char *msg, char *time);

static int ntp_updated(void)
{
	FILE *fp;
	static int updated;

	if(updated || update_first_time())
		return 1;
	fp = fopen("/tmp/ntp_updated","r");

	if(fp == NULL)
		return 0;

	fclose(fp);
	system("touch "NTP_FTIME);
	updated = 1;
	/*get the NTP time firstly,update the log messgaes*/
	generate_log_message(1,logcy);

	return 2;
}
#endif
#define LOG_LEN 1024
void cut_log(char *msg,char *cut_str,int max_len)
{
	char *log_end;
	char tmp_str[LOG_LEN];
	int log_end_len;
	int log_pre_len;
	int last_tag = 0;

	log_end = strstr(msg,cut_str);
	/*if we cannot find the cut_str,just cut directly*/
	if(log_end == NULL){
		msg[max_len] = '\0';
		return;
	}

	log_end_len = strlen(log_end);
	if(strcmp(cut_str,"]") == 0 ){
		log_end = strrchr(msg,']');
		log_end_len = strlen(log_end);
	}
	log_pre_len = max_len - log_end_len;

	msg[log_pre_len] = '\0';
	strcpy(tmp_str,log_end);
	strcpy(msg+log_pre_len,tmp_str);
}
/* 9. [Dynamic DNS] host name x.x.x.x registration successful or failure, Monday, February 20, 2006 04:56:01
 * 17. [email failed] Bare LFs'(the error message returned by mail agent), Monday, February
 */
void check_log_len(char * msg, int time_len)
{
#define LOG_ITEM_SIZE   128
	int log_len;
	int log_max_len;
	int log_max_size = LOG_ITEM_SIZE;

	log_len = strlen(msg);
	log_max_len = log_max_size - time_len;

	if (log_len <= log_max_len)
		return;



	if (strncasecmp(msg, "[Dynamic DNS]", strlen("[Dynamic DNS]")) == 0) {

		cut_log(msg, " registration", log_max_len);
		return;
	}

	if (strncasecmp(msg, "[USB device attached]", strlen("[USB device attached]")) == 0) {

		cut_log(msg, " is attached to the router", log_max_len);
		return;
	}

	if (strncasecmp(msg, "[USB device detached]", strlen("[USB device detached]")) == 0) {

		cut_log(msg, " is detached from the router", log_max_len);
		return;
	}

	if ((strncasecmp(msg, "[site allowed:", strlen("[site allowed:")) == 0) ||
		(strncasecmp(msg, "[site blocked:", strlen("[site blocked:")) == 0))
		   	{

		cut_log(msg, "]", log_max_len);
		return;
	}
	if (strncasecmp(msg, "[Block Attack]", strlen("[Block Attack]")) == 0) {
		cut_log(msg, "Known BOT Attacks and Port Scans", log_max_len);
		return;
	}
	/*default cutting*/
	msg[log_max_len] = '\0';
	return;
}
#if ENABLE_FEATURE_VENDOR_FORMAT_LOG

struct log_category{
	char *name;
	int index;
};

/*LOG														INDEX
 *Attempted access to allowed sites                         1
 *Attempted access to blocked sizes and services            2
 *Connection to the Web-based interface of this Router      3
 *Router opertation                                         4
 *Known Dos attacks and port scans                          5	
 *Port forwarding and port triggering                       6
 *Wireless access                                           7
 *Automatic Internet connection reset                       8
 *ReadyShare                                                9
 *ReadyShare Mobile Connect                                10
 * */

struct log_category reg_logs[]={
	{"Initialized, firmware version",                       4},     /*  Router operation */
	{"Time synchronized with NTP server",                   4},     /*  Router operation */
	{"Internet connected",                                  4},     /*  Router operation */
	{"Internet disconnected",                               4},     /*  Router operation */
	{"Internet idle-timeout",                               4},     /*  Router operation */
	{"WLAN access rejected",                                7},     /*  Wireless access */
	{"DHCP IP",                                             4},     /*  Router operation */
	{"UPnP set event",                                      4},     /*  Router operation */
	{"Dynamic DNS",                                         4},     /*  Router operation */
	{"FAN FAULT",                                           4},     /*  Router operation */
	{"HDD ERROR",                                           4},     /*  Router operation */
	{"admin login",                                         3},     /*  Connections to the Web-based interface of this Router */
	{"remote login",                                        3},     /*  Connections to the Web-based interface of this Router */
	{"admin login failure",                                 3},     /*  Connections to the Web-based interface of this Router */
	{"remote login failure",                                3},     /*  Connections to the Web-based interface of this Router */
	{"site blocked",                                        2},     /*  Attempted access to blocked sites and services */
	{"site allowed",                                        1},     /*  Attempted access to allowed sites */
	{"service blocked",                                     2},     /*  Attempted access to blocked sites and services */
	{"email sent to",                                       4},     /*  Router operation */
	{"email failed",                                        4},     /*  Router operation */
	{"WLAN access denied",                                  7},     /*  Wireless access */
	{"WLAN access allowed",                                 7},     /*  Wireless access */
	{"DoS Attack",                                          5},     /*  Known DoS attacks and Port Scans */
	{"LAN access from remote",                              6},     /*  Port Forwarding/Port Triggering */
	{"Traffic Meter",                                       4},     /*  Router operation */
	{"trafficmeter",                                        4},     /*  Router operation */
	{"Internet disconnected",                               8},     /*  Automatic Internet connection reset */
	{"Wireless signal schedule",                            12},     /*  Ready Share */
	{"Log Cleared",                                         4},     /*  Record the action of clearing logs */
	{"USB device attached",                                 9},     /*  ReadyShare */
	{"USB device detached",                                 9},     /*  ReadyShare */
	{"One Touch Backup",                                    9},     /*  ReadyShare */
	{"Internet HDD detection",                              9},     /*  ReadyShare */
	{"USB remote access",                                   6},     /*  Port Forwarding/Port Triggering */
	{"USB remote access rejected",                          6},     /*  Port Forwarding/Port Triggering */
	{"Access Control",                                      4},     /*  Router operation */
	{"3G/4G",                                              10},     /*  ReadyShare Mobile Connect */
	{"SD card attached",                                   10},     /*  ReadyShare */
	{"OpenVPN",                                            11},     /*  VPN */
	{"DFS radar",                                          12},     /*  VPN */
	{"Block Attack",								4},		/* Router operation */
	{NULL,                                                  0},		 
};
/*
 *       msg[0] = atoi(config_get("log_allow_sites"));
 *       msg[1] = atoi(config_get("log_block_sites_services"));
 *       msg[2] = atoi(config_get("log_conn_web_interface"));
 *       msg[3] = atoi(config_get("log_router_operation"));
 *       msg[4] = atoi(config_get("log_dos_attacks_port_scans"));
 *       msg[5] = atoi(config_get("log_port_firwarding_trigering"));
 *       msg[6] = atoi(config_get("log_wire_access"));
 *       msg[7] = atoi(config_get("log_auto_conn_reset"));
 *       msg[8] = atoi(config_get("log_wifi_off_shedule"));
 */
void get_log_category(int logmsg,int msg[])
{
	msg[0]  = (logmsg >> 0)  & 0x01;
	msg[1]  = (logmsg >> 1)  & 0x01;
	msg[2]  = (logmsg >> 2)  & 0x01;
	msg[3]  = (logmsg >> 3)  & 0x01;
	msg[4]  = (logmsg >> 4)  & 0x01;
	msg[5]  = (logmsg >> 5)  & 0x01;
	msg[6]  = (logmsg >> 6)  & 0x01;
	msg[7]  = (logmsg >> 7)  & 0x01;
	msg[8]  = (logmsg >> 8)  & 0x01;
	msg[9]  = (logmsg >> 9)  & 0x01;
	msg[10] = (logmsg >> 10) & 0x01;
	msg[11] = (logmsg >> 11) & 0x01;
}
static long uptime()
{
	struct sysinfo info;
	sysinfo(&info);
	return info.uptime;
}
int update_first_time()
{
	if(access(NTP_FTIME, 0) == 0)
		return 1;
	else
		return 0;
}
int check_log_category(char msg[],int log_info[])
{
	int i;
	struct log_category *log_map;

	for(i = 0; reg_logs[i].name; i++){
		log_map = & reg_logs[i];
		if(log_info[log_map->index - 1] && (strncmp(&msg[1], log_map->name, strlen(log_map->name))) == 0){
			if((log_map->index == 4 && strstr(msg, "24hr automatic disconnection")) ||
				(log_map->index ==8 && strstr(msg, "24hr sutomatic disconnection")))
				continue;
			return 1;
		}
	}
	return -1;
}
/*when having received the signal SIGUSR1, we set regenerate_log_flag*/
void regenerate_log_by_signal()
{
	regenerate_log_flag = 1;
}
/*eg: 120:[Initialized, firmware version: xxxx] Monday, February 20, 2006 04:56:23 */
void format_log_message(char *buf, time_t *time, char *msg)
{
	char *s;
	
	s = strchr(buf,':');
	*s = '\0';
	*time = atol(buf);

	s++;
	strcpy(msg,s);
	msg[strlen(msg) - 1] = '\0';

	return;
}
void syslog_edit_comma(char *log_message, int flag, int time_len);
int generate_log_message(int flag,int info)
{
	FILE *fp;
	FILE *flog;
	time_t now;
	time_t s_time;
	time_t systime;
	time_t logtime;
	time_t loguptime;
	char loc_time[128];
	char buffer[LOG_LEN];
	char log_message[LOG_LEN];
	int log_info[11];

	time(&now);
	systime = uptime();
	s_time = now - systime;



	char cmd[128];
	char *tempMsg="/var/log/message-temp";
	snprintf(cmd,128,"tac %s > %s", SYSLOG_FILE, tempMsg);
	system(cmd);

	if ((fp = fopen(tempMsg,"r")) == NULL || (flog = fopen(G.logFile.path,"w")) == NULL ){
		if(fp != NULL)
			fclose(fp);
		printf("syslogd cannot open the temparary log file %s or %s\n",SYSLOG_FILE,G.logFile.path);
		return -1;
	}
	/*get the log category information*/
	get_log_category(info,log_info);
	
	memset(loc_time,0,128);
	memset(buffer,0,LOG_LEN);
	memset(log_message,0,LOG_LEN);

	while(fgets(buffer,LOG_LEN,fp)){
		format_log_message(buffer,&loguptime,log_message);	
		/*if user needn't this log,skip it*/
		if(check_log_category(log_message, log_info) < 0)
			continue;

		if(flag){
			logtime = s_time + loguptime;
			/*Time format looks like: Monday, October 1, 1999 14:08:17 */
			strftime(loc_time,sizeof(loc_time),"%A, %B %d, %Y %T",localtime(&logtime));
			/*there is a space before time field,so plus 1*/
			check_log_len(log_message,strlen(loc_time)+1);
			if(strncmp("[3G", log_message, 3) == 0)
				set_mobile_log(log_message, log_message, loc_time);
			else{
				syslog_edit_comma(log_message,flag,strlen(loc_time)+1);
				sprintf(log_message, "%s %s", log_message, loc_time);
			}
		}
		else if(flag ==0){
			check_log_len(log_message,0);
			syslog_edit_comma(log_message,flag,strlen(loc_time)+1);
		}
		fprintf(flog,"%s\n",log_message);
		if(strstr(log_message, "Log Cleared"))
			break;
	}
	fclose(fp);
	fclose(flog);

	/*limit the messages size*/
	while(1){
		int isRegular = 0;
		int cursize = 0;
		struct stat statf;
		isRegular = (stat(G.logFile.path, &statf) == 0 && (statf.st_mode & S_IFREG));
		cursize = statf.st_size;
		
		if(isRegular && cursize > G.logFileSize)
			limit_log_len(G.logFile.path,G.logFileSize,LOG_DEL_NUM);
		else 
			break;
	}

	snprintf(cmd,128, "tac %s > %s",G.logFile.path, tempMsg);
	system(cmd);
	snprintf(cmd, 128, "cat %s > %s", tempMsg, G.logFile.path);
	system(cmd);

	return 0;
}
void update_log(int loginfo)
{
	int ret;

	ret = ntp_updated();
	if(ret == 1)
		generate_log_message(1,loginfo);
	else if(ret == 2)
		generate_log_message(0,loginfo);
	
	return;
}

/*determine if the log should be displayed in the UI*/
int check_log_message(char *msg,int loginfo)
{
	int log_msg[12];
	
	get_log_category(loginfo,log_msg);
	if(check_log_category(msg,log_msg) < 0)
		return -1;
	return 1;
}

int record_log_messages(char *msg, time_t log_uptime)
{
	FILE *fp;
	
	limit_log_len(SYSLOG_FILE, logorgsize, LOG_ORG_DEL_NUM);

	fp = fopen(SYSLOG_FILE,"a+");
	if(fp == NULL){
		printf("Fail to open the file %s\n",SYSLOG_FILE);
		return -1;
	}

	fprintf(fp,"%ld:%s\n", log_uptime, msg);

	fclose(fp);

	return 0;
}
/*some messages' duplicates are meaningful,such as [admin login],so we should not supress them*/
int not_supress_msg(char *msg)
{
	char excp[][LOG_ITEM_SIZE + 1] = {
		"[admin login]",
		"[admin login failure]",
		"[One Touch Backup]",
		"[Log Cleared]",
		"[Dynamic DNS]",
		"[FAN FAULT]",
		"[HDD ERROR]",
		"[remote login]",
		"[remote login failure]",
		"[DHCP IP]",
		"[Block Attack]"};
	int i = 0;
	while(i < sizeof (excp) / sizeof(excp[0])){
		if(strncmp(msg,excp[i],strlen(excp[i])) == 0)
			return 1;
		i++;
	}
	return 0;
}
#endif

/*Bug 29004 - [Log]There should be a comma before the NTP time on
 *the log if the log is too long *and is cut off
 *
 *There should be a comma before the NTP time(Router Spec 2.0).
 *There should be no comma behind the logs if there is no  NTP time.
 *The function syslog_edit_comma is used to process the comma
 */
void syslog_edit_comma(char *msg,int flag,int time_len)
{
#define  LOG_ITEM_SIZE  128

	char tmp_msg[LOG_ITEM_SIZE + 1] = "";
	int tmp_len = 0;
	int max_log_len;

	max_log_len = LOG_ITEM_SIZE - time_len;
	strncpy(tmp_msg,msg,LOG_ITEM_SIZE);
	tmp_len = strlen(tmp_msg) - 1;
	while((tmp_len > 0) && (tmp_msg[tmp_len] == ' ')){
		tmp_len--;
	}
	if(flag == 1)
	{
		if((tmp_msg[tmp_len] != ',') && (tmp_msg[tmp_len] != ']'))
		{
			if((tmp_len + 1) < max_log_len)
				tmp_msg[tmp_len + 1] = ',';
			else
				tmp_msg[tmp_len] = ',';
		}	
	}
	else if(flag == 0)
		{
			if(tmp_msg[tmp_len] == ',')
				tmp_msg[tmp_len] = ' ';
		}
	strncpy(msg,tmp_msg,LOG_ITEM_SIZE);
}
/*The timestamp of 3G/4G's log is in the middle,so some special operations is done here.*/
static void set_mobile_log(char *src, char *msg, char *time)
{
	char prefix[LOG_LEN],buffer[LOG_LEN];
	char *ptr;

	if(time == NULL){
		sprintf(src, "%s\n", msg);
		return;
	}

	strcpy(prefix,msg);
	strcpy(buffer,msg);
	/*the timestamp is always before "VID"*/
	ptr = strcasestr(prefix,"VID");
	if(ptr)
		*ptr = '\0';
	ptr = strcasestr(buffer,"VID");
	if(!ptr)
		sprintf(src, "%s\n", msg);
	else
		sprintf(src, "%s %s, %s\n", prefix, time, ptr);
}

/* len parameter is used only for "is there a timestamp?" check.
 * NB: some callers cheat and supply len==0 when they know
 * that there is no timestamp, short-circuiting the test. */
static void timestamp_and_log(int pri, char *msg, int len)
{
	char *timestamp;
	time_t now;
	int mobile_log = 0;
	int block_site_flag = 0;
#if ENABLE_FEATURE_VENDOR_FORMAT_LOG
	char *skip;
	/*
	 * [NETGEAR SPEC V1.7] 7.3.1 Overall Requirements:
	 * The maximum message length is 128 characters in each entry.
	 */
	 static char last_msg[LOG_ITEM_SIZE + 1];
#endif

	/* Jan 18 00:11:22 msg... */
	/* 01234567890123456 */
	if (len < 16 || msg[3] != ' ' || msg[6] != ' '
	 || msg[9] != ':' || msg[12] != ':' || msg[15] != ' '
	) {
		time(&now);
		timestamp = ctime(&now) + 4; /* skip day of week */
	} else {
		now = 0;
		timestamp = msg;
		msg += 16;
	}
	timestamp[15] = '\0';

#if ENABLE_FEATURE_VENDOR_FORMAT_LOG
	if (strcmp(vendor, "NETGEAR") == 0) {
		/*
		 * [NETGEAR SPEC V1.7] 7.3.2 Events to be logged:
		 *
		 * [Initialized, firmware version: xxx] Monday, February 20, 2006 04:56:01
		 *
		 * syslogd: Jan  1 08:08:21 WNDR3700 user.info syslog: [admin login] from source 192.168.1.13
		 * ...
		 * ...
		 * @msg: WNDR3700 user.info syslog: [admin login] from source 192.168.1.13
		 * skip `WNDR3700 user.info syslog: `, point to `[admin login] from source 192.168.1.13`
		 */
		skip = msg;
		while (*skip != ':' && *skip)
			skip++;
		if (*skip == '\0')
			return;
		skip++;
		if (*skip == ' ')
			skip++;
		msg = skip;
		if(strncmp("[3G", msg, 3) == 0)
			mobile_log = 1;

		/* Only messages start with '[' will be logged */
		if ((msg[0] != '[') || (msg[1] >= '0' && msg[1] <= '9') && mobile_log != 1)
			return;

		/* supress duplicates */
		if (strncmp(last_msg, msg, LOG_ITEM_SIZE)
			   	|| not_supress_msg(msg) 
				|| strstr(msg, "site blocked") != NULL)	//site blocked message should be saved in "/var/log/block-site-messages"
	   	{
			time_t now;
			time_t loguptime;
			char loc_tm[128];

			if (strncmp(last_msg, msg, LOG_ITEM_SIZE) == 0 && strstr(msg, "site blocked") != NULL)
				block_site_flag = 1;

			strncpy(last_msg, msg, LOG_ITEM_SIZE);

			/* Time format looks like: 'Monday, October 1,1999 14:08:57' */
			time(&now);
			loguptime = uptime();
			/*save all the log messages*/
			record_log_messages(msg,loguptime);
			strftime(loc_tm, sizeof(loc_tm), "%A, %B %d, %Y %T", localtime(&now));

			if(strcmp(vendor,"NETGEAR") == 0){	/*not necessary,but it's ok*/
				int ntp_flag;
				ntp_flag = ntp_updated();
				/*fix bug 28901,we should regenerate the log after the NTP server's time changed*/
				if(regenerate_log_flag)
				{
					generate_log_message(1,logcy);
					regenerate_log_flag = 0;
					return;	/*the same reason as ntp_flag == 2*/
				}
				/*the NTP_FTIME exists, the ntp has been updated,thus the log will dispaly in given format*/
				if(ntp_flag == 1){
					check_log_len(msg,strlen(loc_tm)+1);
					if(mobile_log == 1){
						set_mobile_log(G.printbuf, msg, loc_tm);
					}
					else{
						syslog_edit_comma(msg,ntp_flag,strlen(loc_tm)+1);
						sprintf(G.printbuf, "%s %s\n", msg, loc_tm);
					}
				}
				/* the ntp is updated first time, and the function generate_log_message refreshed the 
				 * logs recorded in log_message with given format, including the log a moment ago.in
				 * former process,the log will also be printed once again,so we do some changes here.
				 * */
				else if(ntp_flag == 2){
					return;
				}
				else if(ntp_flag == 0){ /*delete unwanted comma since no time precedes*/

					check_log_len(msg,0);
					if(mobile_log == 1){
						set_mobile_log(G.printbuf, msg, NULL);
					}
					else{
						syslog_edit_comma(msg,ntp_flag,strlen(loc_tm)+1);
						sprintf(G.printbuf, "%s\n",msg);
					}
				}
				/*wait NTPupdate run...,because this log may not should be display,
				 * but NTP time have been firstly got,we should regenerate the log
				 * message
				 * */
				if (check_log_message(msg, logcy) < 0)
					return;
			}
			else	
			{	
				sprintf(G.printbuf, "%s %s\n", msg, loc_tm);
			}


			//when message precedes with [site blocked], record it in BLOCK_SITE_LOG	
			if(strstr(msg, "site blocked") != NULL)
			{
				FILE *fp;
				if ((fp = fopen(BLOCK_SITE_LOG, "w")) == NULL)	
					printf("Open file %s failed.\n", BLOCK_SITE_LOG);
				else
				{
					fprintf(fp, "%s", G.printbuf);
					fclose(fp);
				}
			}

			/*Only when the message is not last site blocked message*/
			if(block_site_flag != 1)
				log_locally(now, G.printbuf, &G.logFile);


		}
	}else {	/*Not specified vendor name*/
		time_t now;
		time(&now);

		sprintf(G.printbuf, "WRONG VENDOR FORMAT, use -V VENDOR_NAME, now support vendor name : NETGEAR\n");
		log_locally(now, G.printbuf, &G.logFile);
	}
#else
	if (option_mask32 & OPT_kmsg) {
		log_to_kmsg(pri, msg);
		return;
	}

	if (option_mask32 & OPT_small)
		sprintf(G.printbuf, "%s %s\n", timestamp, msg);
	else {
		char res[20];
		parse_fac_prio_20(pri, res);
		sprintf(G.printbuf, "%s %.64s %s %s\n", timestamp, G.hostname, res, msg);
	}

	/* Log message locally (to file or shared mem) */
#if ENABLE_FEATURE_SYSLOGD_CFG
	{
		bool match = 0;
		logRule_t *rule;
		uint8_t facility = LOG_FAC(pri);
		uint8_t prio_bit = 1 << LOG_PRI(pri);

		for (rule = G.log_rules; rule; rule = rule->next) {
			if (rule->enabled_facility_priomap[facility] & prio_bit) {
				log_locally(now, G.printbuf, rule->file);
				match = 1;
			}
		}
		if (match)
			return;
	}
#endif
	if (LOG_PRI(pri) < G.logLevel) {
#if ENABLE_FEATURE_IPC_SYSLOG
		if ((option_mask32 & OPT_circularlog) && G.shbuf) {
			log_to_shmem(G.printbuf);
			return;
		}
#endif
		log_locally(now, G.printbuf, &G.logFile);
	}
#endif
}

static void timestamp_and_log_internal(const char *msg)
{
	/* -L, or no -R */
	if (ENABLE_FEATURE_REMOTE_LOG && !(option_mask32 & OPT_locallog))
		return;
	timestamp_and_log(LOG_SYSLOG | LOG_INFO, (char*)msg, 0);
}

/* tmpbuf[len] is a NUL byte (set by caller), but there can be other,
 * embedded NULs. Split messages on each of these NULs, parse prio,
 * escape control chars and log each locally. */
static void split_escape_and_log(char *tmpbuf, int len)
{
	char *p = tmpbuf;

	tmpbuf += len;
	while (p < tmpbuf) {
		char c;
		char *q = G.parsebuf;
		int pri = (LOG_USER | LOG_NOTICE);

		if (*p == '<') {
			/* Parse the magic priority number */
			pri = bb_strtou(p + 1, &p, 10);
			if (*p == '>')
				p++;
			if (pri & ~(LOG_FACMASK | LOG_PRIMASK))
				pri = (LOG_USER | LOG_NOTICE);
		}

		while ((c = *p++)) {
			if (c == '\n')
				c = ' ';
			if (!(c & ~0x1f) && c != '\t') {
				*q++ = '^';
				c += '@'; /* ^@, ^A, ^B... */
			}
			*q++ = c;
		}
		*q = '\0';

		/* Now log it */
		timestamp_and_log(pri, G.parsebuf, q - G.parsebuf);
	}
}

#ifdef SYSLOGD_MARK
static void do_mark(int sig)
{
	if (G.markInterval) {
		timestamp_and_log_internal("-- MARK --");
		alarm(G.markInterval);
	}
}
#endif

/* Don't inline: prevent struct sockaddr_un to take up space on stack
 * permanently */
static NOINLINE int create_socket(void)
{
	struct sockaddr_un sunx;
	int sock_fd;
	char *dev_log_name;

#if ENABLE_FEATURE_SYSTEMD
	if (sd_listen_fds() == 1)
		return SD_LISTEN_FDS_START;
#endif

	memset(&sunx, 0, sizeof(sunx));
	sunx.sun_family = AF_UNIX;

	/* Unlink old /dev/log or object it points to. */
	/* (if it exists, bind will fail) */
	strcpy(sunx.sun_path, _PATH_LOG);
	dev_log_name = xmalloc_follow_symlinks(_PATH_LOG);
	if (dev_log_name) {
		safe_strncpy(sunx.sun_path, dev_log_name, sizeof(sunx.sun_path));
		free(dev_log_name);
	}
	unlink(sunx.sun_path);

	sock_fd = xsocket(AF_UNIX, SOCK_DGRAM, 0);
	xbind(sock_fd, (struct sockaddr *) &sunx, sizeof(sunx));
	chmod(_PATH_LOG, 0666);

	return sock_fd;
}

#if ENABLE_FEATURE_REMOTE_LOG
static int try_to_resolve_remote(remoteHost_t *rh)
{
	if (!rh->remoteAddr) {
		unsigned now = monotonic_sec();

		/* Don't resolve name too often - DNS timeouts can be big */
		if ((now - rh->last_dns_resolve) < DNS_WAIT_SEC)
			return -1;
		rh->last_dns_resolve = now;
		rh->remoteAddr = host2sockaddr(rh->remoteHostname, 514);
		if (!rh->remoteAddr)
			return -1;
	}
	return xsocket(rh->remoteAddr->u.sa.sa_family, SOCK_DGRAM, 0);
}
#endif

#define SNPRINTTS(s, n, format,...) snprintf(s, n, format, ##__VA_ARGS__);

static void rfc5424_timestamp(char ts[], size_t sz)
{
	struct timeval tv;
	struct tm *tm;
	gettimeofday(&tv, NULL);
	if((tm = localtime(&tv.tv_sec)) != NULL) {
		char fmt[64];
		const size_t i = strftime(fmt, sizeof(fmt), "%Y-%m-%dT%H:%M:%S.%%06u%zZ ", tm);
		fmt[i-1] = fmt[i-2];
		fmt[i-2] = fmt[i-3];
		fmt[i-3] = fmt[i-4];
		fmt[i-4] = ':';

		SNPRINTTS(ts, sz-1, fmt, tv.tv_usec);
	}
}

#if ENABLE_FEATURE_INSIGHT_LOG
static void log2rfc5424(char *log5424, char *log, size_t sz)
{
	char *p = log, *pri, *content;
	char ts[128]= {0}, hostname[64] = {0};
	int tsc = 0;
	while(p != NULL) {
		if(*p == '<')
			pri = p+1;
		if(*p == '>')
			*p = '\0';

		if(*p == ' ') {
			while(p != NULL && *p == ' ')
				p++;
			tsc++;
		}
		if(tsc == 3) {
			content = p;
			break;
		}
		p++;
	}

	rfc5424_timestamp(ts, sizeof(ts));
	gethostname(hostname, sizeof(hostname)-1);
	snprintf(log5424, sz,  "<%s>1 %s %s %s", pri, ts, hostname, content);
}

static void do_insight_log(char *log)
{
	char *insight_log_dir = "/var/insight/log";
	char *insight_log_file = "/var/insight/log/insight.log";
	char *insight_log_mark = "[Insight]";
	FILE *fp = NULL;
	char log5424[BUFSIZ+512];

	if(strstr(log, insight_log_mark) == NULL)
		return;

	if(access(insight_log_dir, F_OK) == -1) {
		mkdir(insight_log_dir, S_IRWXU | S_IRWXG | S_IRWXO);
	}

	if((fp = fopen(insight_log_file, "a+"))) {
		log2rfc5424(log5424, log, sizeof(log5424));
		fprintf(fp, "%s\n", log5424);
		fclose(fp);
	}
}
#endif

static void do_syslogd(void) NORETURN;
static void do_syslogd(void)
{
#if ENABLE_FEATURE_REMOTE_LOG
	llist_t *item;
#endif
#if ENABLE_FEATURE_SYSLOGD_DUP
	int last_sz = -1;
	char *last_buf;
	char *recvbuf = G.recvbuf;
#else
#define recvbuf (G.recvbuf)
#endif

	/* Set up signal handlers (so that they interrupt read()) */
	signal_no_SA_RESTART_empty_mask(SIGTERM, record_signo);
	signal_no_SA_RESTART_empty_mask(SIGINT, record_signo);
	//signal_no_SA_RESTART_empty_mask(SIGQUIT, record_signo);
	signal(SIGHUP, SIG_IGN);
#ifdef SYSLOGD_MARK
	signal(SIGALRM, do_mark);
	alarm(G.markInterval);
#endif
#if ENABLE_FEATURE_VENDOR_FORMAT_LOG
	signal(SIGUSR1,regenerate_log_by_signal);
#endif
	xmove_fd(create_socket(), STDIN_FILENO);

	if (option_mask32 & OPT_circularlog)
		ipcsyslog_init();

	if (option_mask32 & OPT_kmsg)
		kmsg_init();

	timestamp_and_log_internal("syslogd started: BusyBox v" BB_VER);

	while (!bb_got_signal) {
		ssize_t sz;

#if ENABLE_FEATURE_SYSLOGD_DUP
		last_buf = recvbuf;
		if (recvbuf == G.recvbuf)
			recvbuf = G.recvbuf + MAX_READ;
		else
			recvbuf = G.recvbuf;
#endif
 read_again:
		sz = read(STDIN_FILENO, recvbuf, MAX_READ - 1);
		if (sz < 0) {
			if (!bb_got_signal)
				bb_perror_msg("read from %s", _PATH_LOG);
			break;
		}

		/* Drop trailing '\n' and NULs (typically there is one NUL) */
		while (1) {
			if (sz == 0)
				goto read_again;
			/* man 3 syslog says: "A trailing newline is added when needed".
			 * However, neither glibc nor uclibc do this:
			 * syslog(prio, "test")   sends "test\0" to /dev/log,
			 * syslog(prio, "test\n") sends "test\n\0".
			 * IOW: newline is passed verbatim!
			 * I take it to mean that it's syslogd's job
			 * to make those look identical in the log files. */
			if (recvbuf[sz-1] != '\0' && recvbuf[sz-1] != '\n')
				break;
			sz--;
		}
#if ENABLE_FEATURE_SYSLOGD_DUP
		if ((option_mask32 & OPT_dup) && (sz == last_sz))
			if (memcmp(last_buf, recvbuf, sz) == 0)
				continue;
		last_sz = sz;
#endif
#if ENABLE_FEATURE_REMOTE_LOG
		/* Stock syslogd sends it '\n'-terminated
		 * over network, mimic that */
		recvbuf[sz] = '\n';

		/* We are not modifying log messages in any way before send */
		/* Remote site cannot trust _us_ anyway and need to do validation again */
		for (item = G.remoteHosts; item != NULL; item = item->link) {
			remoteHost_t *rh = (remoteHost_t *)item->data;

			if (rh->remoteFD == -1) {
				rh->remoteFD = try_to_resolve_remote(rh);
				if (rh->remoteFD == -1)
					continue;
			}

			/* Send message to remote logger.
			 * On some errors, close and set remoteFD to -1
			 * so that DNS resolution is retried.
			 */
			if (sendto(rh->remoteFD, recvbuf, sz+1,
					MSG_DONTWAIT | MSG_NOSIGNAL,
					&(rh->remoteAddr->u.sa), rh->remoteAddr->len) == -1
			) {
				switch (errno) {
				case ECONNRESET:
				case ENOTCONN: /* paranoia */
				case EPIPE:
					close(rh->remoteFD);
					rh->remoteFD = -1;
					free(rh->remoteAddr);
					rh->remoteAddr = NULL;
				}
			}
		}
#endif
		if (!ENABLE_FEATURE_REMOTE_LOG || (option_mask32 & OPT_locallog)) {
			recvbuf[sz] = '\0'; /* ensure it *is* NUL terminated */
#if ENABLE_FEATURE_INSIGHT_LOG
			do_insight_log(recvbuf); //save insight log
#endif
			split_escape_and_log(recvbuf, sz);
		}
	} /* while (!bb_got_signal) */

	timestamp_and_log_internal("syslogd exiting");
	remove_pidfile(CONFIG_PID_FILE_PATH "/syslogd.pid");
	ipcsyslog_cleanup();
	if (option_mask32 & OPT_kmsg)
		kmsg_cleanup();
	kill_myself_with_sig(bb_got_signal);
#undef recvbuf
}

int syslogd_main(int argc, char **argv) MAIN_EXTERNALLY_VISIBLE;
int syslogd_main(int argc UNUSED_PARAM, char **argv)
{
	int opts;
	char OPTION_DECL;
#if ENABLE_FEATURE_REMOTE_LOG
	llist_t *remoteAddrList = NULL;
#endif

	INIT_G();

	/* No non-option params, -R can occur multiple times */
	opt_complementary = "=0" IF_FEATURE_REMOTE_LOG(":R::");
	opts = getopt32(argv, OPTION_STR, OPTION_PARAM);
#if ENABLE_FEATURE_REMOTE_LOG
	while (remoteAddrList) {
		remoteHost_t *rh = xzalloc(sizeof(*rh));
		rh->remoteHostname = llist_pop(&remoteAddrList);
		rh->remoteFD = -1;
		rh->last_dns_resolve = monotonic_sec() - DNS_WAIT_SEC - 1;
		llist_add_to(&G.remoteHosts, rh);
	}
#endif

#ifdef SYSLOGD_MARK
	if (opts & OPT_mark) // -m
		G.markInterval = xatou_range(opt_m, 0, INT_MAX/60) * 60;
#endif
	//if (opts & OPT_nofork) // -n
	//if (opts & OPT_outfile) // -O
	if (opts & OPT_loglevel) // -l
		G.logLevel = xatou_range(opt_l, 1, 8);
	//if (opts & OPT_small) // -S
#if ENABLE_FEATURE_ROTATE_LOGFILE
	if (opts & OPT_filesize) // -s
		G.logFileSize = xatou_range(opt_s, 0, INT_MAX/1024) * 1024;
	if (opts & OPT_rotatecnt) // -b
		G.logFileRotate = xatou_range(opt_b, 0, 99);
#endif
#if ENABLE_FEATURE_IPC_SYSLOG
	if (opt_C) // -Cn
		G.shm_size = xatoul_range(opt_C, 4, INT_MAX/1024) * 1024;
#endif
	/* If they have not specified remote logging, then log locally */
	if (ENABLE_FEATURE_REMOTE_LOG && !(opts & OPT_remotelog)) // -R
		option_mask32 |= OPT_locallog;
#if ENABLE_FEATURE_SYSLOGD_CFG
	parse_syslogdcfg(opt_f);
#endif

#if ENABLE_FEATURE_TIMEZONE_LOG
	if(opts & OPT_timezone )	//-T
		if(opt_T != 0)
			xsetenv("TZ",opt_T);
#endif
#if ENABLE_FEATURE_VENDOR_FORMAT_LOG
	if (opts & OPT_vendor) { // -V
		/*
		 *  Log message format according the vendor required, like NETGEAR
		 */
		if (strlen(opt_V) < sizeof(vendor)) {
			memset(vendor, 0, sizeof(vendor));
			strcpy(vendor, opt_V);
		}
	}
	if(opts & OPT_logcategory){
		if(*opt_c != NULL){
			logcy = atoi(opt_c);
		}
		update_log(logcy);
	}
#endif

	/* Store away localhost's name before the fork */
	G.hostname = safe_gethostname();
	*strchrnul(G.hostname, '.') = '\0';

	if (!(opts & OPT_nofork)) {
		bb_daemonize_or_rexec(DAEMON_CHDIR_ROOT, argv);
	}

	//umask(0); - why??
	write_pidfile(CONFIG_PID_FILE_PATH "/syslogd.pid");

	do_syslogd();
	/* return EXIT_SUCCESS; */
}

/* Clean up. Needed because we are included from syslogd_and_logger.c */
#undef DEBUG
#undef SYSLOGD_MARK
#undef SYSLOGD_WRLOCK
#undef G
#undef GLOBALS
#undef INIT_G
#undef OPTION_STR
#undef OPTION_DECL
#undef OPTION_PARAM
