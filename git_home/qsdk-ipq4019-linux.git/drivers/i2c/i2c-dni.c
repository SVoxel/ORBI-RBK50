#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/delay.h>
#include <linux/errno.h>
#include <linux/i2c.h>
#include <asm/uaccess.h>
#include <linux/proc_fs.h>

#define I2C_ADDR                0x21  //7 bit 
#define I2C_READ_ADDR           0x41  //8 bit
#define I2C_WRITE_ADDR          0x40  //8 bit

#define INPUT_PORT0_REG         0x00
#define INPUT_PORT1_REG         0x01
#define OUTPUT_PORT0_REG        0x0A
#define OUTPUT_PORT1_REG        0x0B
#define POLARITY_PORT0_REG      0x02
#define POLARITY_PORT1_REG      0x03
#define CONFIG_PORT0_REG        0x08
#define CONFIG_PORT1_REG        0x09

#define I2C_PORT0               0
#define I2C_PORT1               1

#define LED_SYS_R_EN           (1<<0)
#define LED_SYS_G_EN           (1<<1)
#define LED_SYS_Y_EN           (1<<2)
#define LED_INTERNET_R_EN      (1<<3)
#define LED_INTERNET_G_EN      (1<<4)
#define LED_INTERNET_Y_EN      (1<<5)
#define LED_2G_R_EN            (1<<6)
#define LED_2G_G_EN            (1<<7)
#define LED_2G_Y_EN            (1<<0)
#define LED_5G_R_EN            (1<<1)
#define LED_5G_G_EN            (1<<2)
#define LED_5G_Y_EN            (1<<3)
#define LED_ALL_R_PORT0_EN      0x49
#define LED_ALL_G_PORT0_EN      0x92
#define LED_ALL_Y_PORT0_EN      0x24
#define LED_ALL_R_PORT1_EN      0x02
#define LED_ALL_G_PORT1_EN      0x04
#define LED_ALL_Y_PORT1_EN      0x09
#define LED_ALL_EN              0xff

#define LED_SYS_R               0x00
#define LED_SYS_G               0x01
#define LED_SYS_Y               0x02
#define LED_INTERNET_R          0x03
#define LED_INTERNET_G          0x04
#define LED_INTERNET_Y          0x05
#define LED_2G_R                0x06
#define LED_2G_G                0x07
#define LED_2G_Y                0x10
#define LED_5G_R                0x11
#define LED_5G_G                0x12
#define LED_5G_Y                0x13
#define LED_ALL_R               0x14
#define LED_ALL_G               0x15
#define LED_ALL_Y               0x16
#define LED_ALL_C               0x17

static struct i2c_client *g_client = NULL;

int pca9575_read(u8 reg)
{
	int ret;
	printk(" client name=[%s]\n ",g_client->name);
	printk(" client addr =[%x]\n",(g_client->addr & (~(1<<7))));
	if(g_client == NULL)
	{
		printk(KERN_ERR "pca9575 i2c g_client dont exit\n");
		return -1;
	}
	ret = i2c_smbus_read_byte_data(g_client,reg);
	if(ret < 0){
		printk(KERN_ERR "pca9575 i2c read fail! reg=%d \n",reg);
	}
	return ret;
}

int pca9575_write(u8 reg, u8 val)
{
	int ret;

	if(g_client == NULL)
	{
		printk(KERN_ERR "pca9575 i2c g_client dont exit(write)\n");
		return -1;
	}

	ret = i2c_smbus_write_byte_data(g_client,reg,val);
	
	if(ret < 0){
		printk(KERN_ERR "pca9575 i2c write fail! reg =%d\n",reg);
	}

	return ret;
}

int pca9575_config(u8 port_group,u8 port_gpio ,u8 port_val)
{
	unsigned int output_val=0;
	unsigned int Port_config=0;

	if(port_group == I2C_PORT0)
	{
		output_val = pca9575_read(OUTPUT_PORT0_REG);
		printk("Before write:\n");
		printk("output_val: %x\n",output_val);
		switch(port_gpio)
		{
			case LED_SYS_R:
				Port_config = LED_SYS_R_EN;
			  break;
			case LED_SYS_G:
				Port_config = LED_SYS_G_EN;
			  break;
			case LED_SYS_Y:
				Port_config = LED_SYS_Y_EN;
			  break;
			
			case LED_INTERNET_R:
				Port_config = LED_INTERNET_R_EN;
			  break;
			case LED_INTERNET_G:
				Port_config = LED_INTERNET_G_EN;
			  break;
			case LED_INTERNET_Y:
				Port_config = LED_INTERNET_Y_EN;
			  break;

			case LED_2G_R:
				Port_config = LED_2G_R_EN;
			  break;
			case LED_2G_G:
				Port_config = LED_2G_G_EN;
			  break;
			
			case LED_ALL_R:
				Port_config = LED_ALL_R_PORT0_EN;
			  break;
			case LED_ALL_G:
				Port_config = LED_ALL_G_PORT0_EN;
			  break;
			case LED_ALL_Y:
				Port_config = LED_ALL_Y_PORT0_EN;
			  break;
			
			case LED_ALL_C:
				Port_config = LED_ALL_EN;
			  break;
		}
		if (!port_val) {
			output_val &= (~Port_config);
        } else {
			output_val |= Port_config;
        }
		pca9575_write(CONFIG_PORT0_REG,0x00);
		pca9575_write(OUTPUT_PORT0_REG,output_val);
	    printk("ready to write value= [%x]\n",output_val);
	}
	if(port_group == I2C_PORT1)
	{
		output_val = pca9575_read(OUTPUT_PORT1_REG);
		printk("Before write:\n");
		printk("output_val: %x\n",output_val);
		switch(port_gpio)
		{
			case LED_2G_Y:
				Port_config = LED_2G_Y_EN;
			  break;

			case LED_5G_R:
				Port_config = LED_5G_R_EN;
			  break;
			case LED_5G_G:
				Port_config = LED_5G_G_EN;
			  break;
			case LED_5G_Y:
				Port_config = LED_5G_Y_EN;
			  break;
			
			case LED_ALL_R:
				Port_config = LED_ALL_R_PORT1_EN;
			  break;
			case LED_ALL_G:
				Port_config = LED_ALL_G_PORT1_EN;
			  break;
			case LED_ALL_Y:
				Port_config = LED_ALL_Y_PORT1_EN;
			  break;
			
			case LED_ALL_C:
				Port_config = LED_ALL_EN;
			  break;
	    }
		if (!port_val) {
			output_val &= (~Port_config);
        } else {
			output_val |= Port_config;
        }
		pca9575_write(CONFIG_PORT1_REG,0x00);
		pca9575_write(OUTPUT_PORT1_REG,output_val);
	    printk("ready to write value= [%x]\n",output_val);
    }   
	return 0;
}
EXPORT_SYMBOL_GPL(pca9575_config);

static ssize_t show_I2C_pca9575(struct device *dev, struct device_attribute *attr, char *buf)
{
	unsigned int output_port0_val=0;
	unsigned int output_port1_val=0;
	unsigned int config_port0_val=0;
	unsigned int config_port1_val=0;
	unsigned int input_port0_val=0;
	unsigned int input_port1_val=0;
	unsigned int polarity_port0_val=0;
	unsigned int polarity_port1_val=0;
	
	output_port0_val = pca9575_read(OUTPUT_PORT0_REG);
	output_port1_val = pca9575_read(OUTPUT_PORT1_REG);
	config_port0_val = pca9575_read(CONFIG_PORT0_REG);
	config_port1_val = pca9575_read(CONFIG_PORT1_REG);
	input_port0_val = pca9575_read(INPUT_PORT0_REG);
	input_port1_val = pca9575_read(INPUT_PORT1_REG);
	polarity_port0_val = pca9575_read(POLARITY_PORT0_REG);
	polarity_port1_val = pca9575_read(POLARITY_PORT1_REG);

	return  sprintf(buf,"output_port0[%x];output_port1[%x];input_port0[%x];input_port1[%x];config_port0[%x];config_port1[%x];polarity_port0[%x];polarity_port1[%x] \n",output_port0_val,output_port1_val,input_port0_val,input_port1_val,config_port0_val,config_port1_val,polarity_port0_val,polarity_port1_val);
}

static ssize_t set_I2C_pca9575(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
	unsigned int buffer[2]={0xc0,0xc0};
	if(sscanf(buf, "%u %u\n",&buffer[0],&buffer[1]) > 2)
	{
		printk("It seems sscanf not ok !");
		return -EINVAL;
	}
	pca9575_write(CONFIG_PORT0_REG,buffer[0]);
	pca9575_write(OUTPUT_PORT0_REG,buffer[1]);
	pca9575_write(CONFIG_PORT1_REG,buffer[0]);
	pca9575_write(OUTPUT_PORT1_REG,buffer[1]);
	return count;
}

static DEVICE_ATTR(externoutput, S_IRUGO | S_IWUSR, show_I2C_pca9575, set_I2C_pca9575);
static struct attribute *pca9575_sysfs_entries[] = {
	&dev_attr_externoutput.attr,
	NULL
};

static struct attribute_group pca9575_attr_group = {
	.name = NULL,
	.attrs = pca9575_sysfs_entries,
};

static int pca9575_suspend(struct i2c_client *client, pm_message_t state)
{
	printk("pca9575 suspend\n");
	return 0;
}

static int pca9575_resume(struct i2c_client *client)
{
	printk("pca9575 resume\n");
	return 0;
}

static int pca9575_shutdown(struct i2c_client *client)
{
        printk("pca9575 shutdown\n");
        return 0;
}

static int pca9575_probe(struct i2c_client *client, const struct i2c_device_id *id)
{
	int ret=0;

	printk("pca9575 probe\n");
	
	g_client = client;
	
	ret = sysfs_create_group(&client->dev.kobj, &pca9575_attr_group);
	if(ret) {
		printk("error creating sysfs group\n");
		return -1;
	}
	
	return 0;
}

static int pca9575_remove(struct i2c_client *client)
{
	printk("pca9575_remove\n!");
	sysfs_remove_group(&client->dev.kobj, &pca9575_attr_group);
	return 0;
}

static const struct i2c_device_id pca9575_id[] = {
	{"pca9575", 0x21},
	{}
};
static struct i2c_driver pca9575_driver = {
	.driver = {
	 	.name = "pca9575",
	},
	.probe = pca9575_probe,
	.remove = pca9575_remove,
	.id_table = pca9575_id,
	.suspend = pca9575_suspend,
	.resume = pca9575_resume,
	.shutdown = pca9575_shutdown,
};

static int __init pca9575_init(void)
{
	printk("pca9575 init!\n");
	return i2c_add_driver(&pca9575_driver);
}

static void __exit pca9575_exit(void)
{
	i2c_del_driver(&pca9575_driver);
}

module_init(pca9575_init);
module_exit(pca9575_exit);

MODULE_DESCRIPTION("pca9575 driver");
MODULE_LICENSE("GPL");

