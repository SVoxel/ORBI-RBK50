#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include "common.h"


/**
 * Record first NTP Sync Timestamp.
 *
 * It's a track record of the date/time on POT partition fot the first time
 * when the router power on and get time from NTP server.
 *
 * The first 4 bytes in the POT MTD with FIRST_NTP_TIME_OFFSET offset stores the
 * timestamp in the number of seconds since year 1970 in the GMT time.
 **/

#define NTPST_POSTION        2048

extern char pot_mtd_dev[128];


void ntpst_usage(char *name)
{
	fprintf(stderr,
		"\nUsage: %s <get | set>\n"
		"\tget -T [timezone] - display the contents of the NTP Sync Timestamp to 'stdout'.\n"
		"\t-d [mtd_block] - Specifies pot mtd partition.\n"
		"\tset - record now time to POT partition as a NTP Sync Timestamp,\n"
		"\t\tif thers is a NTP Sync Timestamp existed yet, just display\n"
		"\t\tit without any write action.\n",
		name);
	exit(0);
}

int ntpst_func(int argc, char *argv[])
{
	int devfd, sign = 0, ch; /* sign: 0 - get, 1 - set */
	unsigned char buf[NAND_FLASH_PAGESIZE];
	time_t *ntptime = (time_t *)buf;
	char str[128];
	char timezone[64];
	char tz_env[64];
	int skip_size;

	if (!strcmp(argv[1], "get"))
		sign = 0;
	else if (!strcmp(argv[1], "set"))
		sign = 1;

#if SUPPORT_DNITOOLBOX
	devfd = open(pot_mtd_dev, O_RDWR | O_SYNC);
	if (devfd < 0) {
		dfp("can't open mtd device - %s\n", pot_mtd_dev);
		return -1;
	}
#else
	while ((ch = getopt(argc, argv, "T:d:")) != -1) {
		switch(ch) {
			case 'T':
				memset(timezone, 0, sizeof(timezone));
				strcpy(timezone, optarg);
				break;
			case 'd':
				strncpy(pot_mtd_dev, optarg, sizeof(pot_mtd_dev));
				break;
			default:
				break;
		}
	}
	if ((timezone[0] == '\0') || (pot_mtd_dev[0] == '\0')) {
		ntpst_usage(argv[0]);
	}
	devfd = open(pot_mtd_dev, O_RDWR | O_SYNC);
	if (devfd < 0) {
		dfp("can't open mtd device - %s\n", pot_mtd_dev);
		return -1;
	}
#endif

	if(!strcmp(flash_type,"EMMC")){
		lseek(devfd, NTPST_POSTION, SEEK_SET);
		read(devfd, &ntptime, sizeof(ntptime));

		if (0 == sign) {
			if (0xFFFFFFFF == ntptime) {
				printf("NTP synchronized date/time: 00-00-00\n");
			} else {
				memset(timezone, 0, 64);
				strcpy(timezone, config_get("time_zone"));
				sprintf(tz_env, "TZ=%s", timezone);
				putenv(tz_env);
				strftime(str, sizeof(str), "%T, %b %d, %Y",localtime(&ntptime));
				printf("NTP synchronized date/time: %s\n", str);
			}
		} else {
			if (0xFFFFFFFF != ntptime) {
				strftime(str, sizeof(str), "%T, %b %d, %Y", localtime(&ntptime));
				printf("NTPST: one NTP Sync Timestamp existed in POT partition, it's %s\n", str);
			} else {
				ntptime = time(NULL);
				lseek(devfd, -4, SEEK_CUR);
				write(devfd, &ntptime, sizeof(ntptime));
				strftime(str, sizeof(str), "%T, %b %d, %Y", localtime(&ntptime));
				printf("NTPST: NTP Sync Timestamp record finished, it's %s\n", str);
			}
		}
	} else {
		skip_size = find_good_nand_block(devfd, FIRST_NTP_TIME_OFFSET);   
		if(skip_size == -1){
			fprintf(stderr, "NTPST: no good block, exit now\n");	
			exit(1);
		}
		lseek(devfd, FIRST_NTP_TIME_OFFSET, SEEK_SET);
		read(devfd, buf, sizeof(buf));
	
		if (0 == sign) {
			if (0xFFFFFFFF == *ntptime) {
				fprintf(stderr, ":( ntpst - (offset 0x%08X bytes in POT partition) first NTP synchronized date/time: 00-00-00\n", FIRST_NTP_TIME_OFFSET);
			} else {
				sprintf(tz_env, "TZ=%s", timezone);
				putenv(tz_env);
				strftime(str, sizeof(str), "%T, %b %d, %Y",localtime(ntptime));

				fprintf(stderr, ":) ntpst - (offset 0x%08X bytes in POT partition) first NTP synchronized date/time: %s\n", FIRST_NTP_TIME_OFFSET, str);
			}

		} else {
			if (0xFFFFFFFF != *ntptime) {
				strftime(str, sizeof(str), "%T, %b %d, %Y", localtime(ntptime));
				fprintf(stderr, ":( ntpst - (offset 0x%08X bytes in POT partition) one NTP Sync Timestamp existed: %s\n", FIRST_NTP_TIME_OFFSET, str);
			} else {
				*(time_t *)buf = time(NULL);
				lseek(devfd, FIRST_NTP_TIME_OFFSET, SEEK_SET);
				write(devfd, buf, sizeof(buf));
				strftime(str, sizeof(str), "%T, %b %d, %Y", localtime(ntptime));
				fprintf(stderr, ":) ntpst - (offset 0x%08X bytes in POT partition) NTP Sync Timestamp record success: %s\n", FIRST_NTP_TIME_OFFSET, str);
			}
		}
	}
	close(devfd);
	return 0;
}


/**
 * Record MAC address of the first Wi-Fi STA that connects to the router after it came out from the factory.
 *
 * the first 6 bytes in the POT partition with FIRST_WIFISTATION_MAC_OFFSET offset stores MAC address of the
 * first connected wifi station in the process of user using DUT.
 *
 * Basically it works this way:
 * Every time when there is a Wi-Fi STA connected to a router since it boots up, 
 * the router checks whether there is a MAC address stored on the 6 bytes (i.e. whether the first byte of the 6 bytes is 0xff).
 * If the 6 bytes do not record a MAC address information, the router stores the MAC address of this Wi-Fi STA to the 6 bytes.
 * Or else no action is performed.
 */

void stamac_usage(char *name)
{
	printf("\nUsage: %s <get | set <mac address>>\n"
		"\tget - display the MAC address of the first Wi-Fi STA that connects to\n"
		"\t\tthe router after it came out from the factory to 'stdout'.\n"
		"\tset xx:xx:xx:xx:xx:xx - record specified MAC address to POT partition,\n"
		"\t\tif thers is a MAC address existed yet, just display\n"
		"\t\tit without any write action.\n",
		name);
	exit(0);
}

int stamac_func(int argc, char *argv[])
{
	int ch;
	int devfd, count, sign = 0;	/* sign: 0 - get, 1 - set */
	unsigned char buf[NAND_FLASH_PAGESIZE];
	struct mac_t {
		unsigned char byte0;
		unsigned char byte1;
		unsigned char byte2;
		unsigned char byte3;
		unsigned char byte4;
		unsigned char byte5;
	} tmp, *mac;
	unsigned int gmac[6];
	char tmp_mac[32] = {0};
	unsigned char mac_emmc[6];
	const unsigned char nomac[6] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
	int byte0, byte1, byte2, byte3, byte4, byte5;
	int skip_size;

	if (!strcmp(argv[1], "get"))
		sign = 0;
	else if (!strcmp(argv[1], "set")){
		sign = 1;
#if SUPPORT_DNITOOLBOX
		if (argv[2] != NULL)
			strncpy(tmp_mac, argv[2], sizeof(tmp_mac));
		else
			stamac_usage(argv[0]);
#endif
	}
	else
		stamac_usage(argv[0]);

#if SUPPORT_DNITOOLBOX
	memset(&tmp, 0xFFFFFFFF, sizeof(tmp));
	mac = (struct mac_t *)buf;

	devfd = open(pot_mtd_dev, O_RDWR | O_SYNC);
#else
	while ((ch = getopt(argc, argv, "d:")) != -1) {
		switch(ch) {
			case 'd':
				strncpy(pot_mtd_dev, optarg, sizeof(pot_mtd_dev));
				break;
			default:
				break;
		}
	}
	if (pot_mtd_dev[0] == '\0')
		stamac_usage(argv[0]);

	memset(&tmp, 0xFFFFFFFF, sizeof(tmp));
	mac = (struct mac_t *)buf;

	devfd = open(pot_mtd_dev, O_RDWR | O_SYNC);
#endif
	if (0 > devfd) {
		printf("stamac: open mtd POT error!\n");
		return -1;
	}

	if(!strcmp(flash_type,"EMMC")){
		lseek(devfd, STAMAC_POSTION, SEEK_SET);
		read(devfd, mac_emmc, sizeof(mac_emmc));
		if (0 == sign) {
			if (!memcmp(nomac, mac_emmc, sizeof(mac_emmc)))
				printf("MAC address of 1st STA connected: 00-00-00-00-00-00\n");
			else
				printf("MAC address of 1st STA connected: %02x-%02x-%02x-%02x-%02x-%02x\n", mac_emmc[0], mac_emmc[1], mac_emmc[2], mac_emmc[3], mac_emmc[4], mac_emmc[5]);
		} else {
			if (memcmp(nomac, mac_emmc, sizeof(mac_emmc))) {
				printf("stamac: one MAC address existed in POT partition, it's %02x-%02x-%02x-%02x-%02x-%02x\n", mac_emmc[0], mac_emmc[1], mac_emmc[2], mac_emmc[3], mac_emmc[4], mac_emmc[5]);
			} else {
				if (6 != sscanf(argv[2], "%x:%x:%x:%x:%x:%x", &byte0, &byte1, &byte2, &byte3, &byte4, &byte5))
					printf("stamac: the MAC address you specified is wrong, must be same as 00:11:22:33:44:55\n");
				else {
					mac_emmc[0] = byte0;
					mac_emmc[1] = byte1;
					mac_emmc[2] = byte2;
					mac_emmc[3] = byte3;
					mac_emmc[4] = byte4;
					mac_emmc[5] = byte5;
					lseek(devfd, -6, SEEK_CUR);
					write(devfd, mac_emmc, sizeof(mac_emmc));
					printf("stamac: STA MAC address record finished, it's %02x-%02x-%02x-%02x-%02x-%02x\n", mac_emmc[0], mac_emmc[1], mac_emmc[2], mac_emmc[3], mac_emmc[4], mac_emmc[5]);
				}
			}
		}
	} else {
		#define MAC_FMT	"%02x:%02x:%02x:%02x:%02x:%02x"
		#define MAC_VAL	mac->byte0, mac->byte1, mac->byte2, mac->byte3, mac->byte4, mac->byte5
		skip_size = find_good_nand_block(devfd, FIRST_WIFISTATION_MAC_OFFSET);   
		if(skip_size == -1){
			fprintf(stderr, "stamac: no good block, exit now\n");	
			exit(1);
		}
		lseek(devfd, skip_size, SEEK_SET);
		read(devfd, buf, sizeof(buf));
		if (0 == sign) {
			if (!memcmp(&tmp, mac, sizeof(tmp)))
				fprintf(stderr, ":( stamac - (offset 0x%08X bytes in POT partition) 1st connected STA's MAC: 00-00-00-00-00-00\n", FIRST_WIFISTATION_MAC_OFFSET);
			else
				fprintf(stderr, ":) stamac - (offset 0x%08X bytes in POT partition) 1st connected STA's MAC: "MAC_FMT"\n", FIRST_WIFISTATION_MAC_OFFSET, MAC_VAL);
		} else {
			if (memcmp(&tmp, mac, sizeof(tmp))) {
				fprintf(stderr, ":( stamac - (offset 0x%08X bytes in POT partition) one 1st connected STA's MAC exsited: "MAC_FMT"\n", FIRST_WIFISTATION_MAC_OFFSET, MAC_VAL);
			} else {
				if (6 == sscanf(tmp_mac, MAC_FMT, &gmac[0], &gmac[1], &gmac[2], &gmac[3], &gmac[4], &gmac[5])) {
					for (count = 0; count < 6; count++)	/* valid MAC address ? */
					{
						buf[count] = (unsigned char)gmac[count];
						if (buf[count] > 0xFF || buf[count] < 0x00)
							break;
					}

					if (count == 6) {
						lseek(devfd, skip_size, SEEK_SET);
						write(devfd, buf, sizeof(buf));
						fprintf(stderr, ":) stamac - (offset 0x%08X bytes in POT partition) 1st connected STA's MAC record success: "MAC_FMT"\n", FIRST_WIFISTATION_MAC_OFFSET, MAC_VAL);
					} else {
						fprintf(stderr, ":( stamac - (offset 0x%08X bytes in POT partition) sorry, invalied MAC address can't be stored: %s\n", FIRST_WIFISTATION_MAC_OFFSET, argv[2]);
					}
				} else {
					fprintf(stderr, ":( stamac - (offset 0x%08X bytes in POT partition) sorry, invalied MAC address can't be stored: %s\n", FIRST_WIFISTATION_MAC_OFFSET, argv[2]);
				}
			}
		}
	#undef MAC_FMT
	#undef MAC_VAL
	}
	close(devfd);
	return 0;
}

#define NETCONN_POSTION (STAMAC_POSTION + 8)
#define NAND_FLASH_PAGESIZE	(2 * 1024)
#define FIRST_INTERNET_CONNECT_OFFSET (FIRST_WIFISTATION_MAC_OFFSET + NAND_FLASH_PAGESIZE + NAND_FLASH_PAGESIZE)

void netconn_usage(char *name)
{
	printf("\nUsage: %s <get | set | clean>\n"
		"\tget - display it connect to internet or not\n"
		"\tset - record the result to POT partition,\n"
		"\tclean - clean the result in POT partition.\n",
		name);
	exit(0);
}

int netconn_func_for_nand(int argc, char *argv[]){
	int devfd, count, sign = 0;	/* sign: 0 - get, 1 - set, 2 - clean */
	unsigned char buf[NAND_FLASH_PAGESIZE];
	struct net_t {
		unsigned char byte0;
		unsigned char byte1;
	} nettmp, *netconn;
	int skip_size;

	if (argc == 2 && !strcmp(argv[1], "get"))
		sign = 0;
	else if (argc == 2 && !strcmp(argv[1], "set"))
		sign = 1;
	else if (argc == 2 && !strcmp(argv[1], "clean"))
		sign = 2;
	else
		netconn_usage(argv[0]);

	memset(&nettmp, 0xFFFF, sizeof(nettmp));
	netconn = (struct net_t *)buf;
	devfd = open(pot_mtd_dev, O_RDWR | O_SYNC);
	if (0 > devfd) {
		printf("netconn: open mtd POT error!\n");
		return -1;
	}

	skip_size = find_good_nand_block(devfd, FIRST_INTERNET_CONNECT_OFFSET);   
	if(skip_size == -1){
		fprintf(stderr, "netconn: no good block, exit now\n");	
		exit(1);
	}
	lseek(devfd, skip_size, SEEK_SET);
	read(devfd, buf, sizeof(buf));
	if (0 == sign) {
		if (!memcmp(&nettmp, netconn, sizeof(nettmp))) {
			printf(":( netconn - (offset 0x%08X bytes in POT partition) Ever connected to Internet (Y/N): No\n", FIRST_INTERNET_CONNECT_OFFSET);
			system("echo No > /tmp/POT_netconn");
		} else {
			printf(":) netconn - (offset 0x%08X bytes in POT partition) Ever connected to Internet (Y/N): Yes\n", FIRST_INTERNET_CONNECT_OFFSET);
			system("echo Yes > /tmp/POT_netconn");
		}
	} else {
        if (1 == sign) {
        	if (memcmp(&nettmp, netconn, sizeof(nettmp))) {
        		printf(":( netconn - (offset 0x%08X bytes in POT partition) one netconn result existed: Yes\n", FIRST_INTERNET_CONNECT_OFFSET);
        	} else {
                for (count = 0; count < 2; count++)
                {
                    buf[count] = 0x00;
                }
                if (count == 2) {
                    lseek(devfd, skip_size, SEEK_SET);
                    write(devfd, buf, sizeof(buf));
                    printf(":) netconn - (offset 0x%08X bytes in POT partition) set netconn result success: Yes\n", FIRST_INTERNET_CONNECT_OFFSET);
                }
        	}
			system("echo Yes > /tmp/POT_netconn");
        } else {
	        unsigned char buf_tmp[NAND_FLASH_PAGESIZE];
			unsigned char buf_tmp_1[NAND_FLASH_PAGESIZE];
	        time_t *ntptime = (time_t *)buf_tmp;
	        lseek(devfd, FIRST_NTP_TIME_OFFSET, SEEK_SET);
            read(devfd, buf_tmp, sizeof(buf_tmp));
            struct mac_t {
                unsigned char byte0;
                unsigned char byte1;
                unsigned char byte2;
                unsigned char byte3;
                unsigned char byte4;
                unsigned char byte5;
            } tmp, *mac;
            memset(&tmp, 0xFFFFFFFF, sizeof(tmp));
            mac = (struct mac_t *)buf_tmp_1;
            lseek(devfd, FIRST_WIFISTATION_MAC_OFFSET, SEEK_SET);
            read(devfd, buf_tmp_1, sizeof(buf_tmp_1));
          
		   // system("flash_erase /dev/mtd16 0x0040000 1");
		   char flash_erase_cmd[256]={0};
		   sprintf(flash_erase_cmd, "flash_erase %s 0x0040000 1", pot_mtd_dev);
		   system(flash_erase_cmd);

            if (0xFFFFFFFF != *ntptime) {
                lseek(devfd, FIRST_NTP_TIME_OFFSET, SEEK_SET);
                write(devfd, buf_tmp, sizeof(buf_tmp));
            }
			if (memcmp(&tmp, mac, sizeof(tmp))) {
                lseek(devfd, FIRST_WIFISTATION_MAC_OFFSET, SEEK_SET);
                write(devfd, buf_tmp_1, sizeof(buf_tmp_1));
            }
       		printf(":( netconn - (offset 0x%08X bytes in POT partition) set netconn result: No\n", FIRST_INTERNET_CONNECT_OFFSET);
			system("echo No > /tmp/POT_netconn");
        }
	}

	close(devfd);
	return 0;
}

int netconn_func_for_emmc(int argc, char *argv[]){
	int devfd = 0;
	int sign = 0; /* 0 - get, 1 - set, 2 - clean */
	int count = 0;
	unsigned char current_con[2], res_con[2];
	const unsigned char nocon[2] = {0xff, 0xff};
	unsigned char buf[NAND_FLASH_PAGESIZE];

	if (!strcmp(argv[1], "get")) {
		sign = 0;
	}
	else if (!strcmp(argv[1], "set")) {
		sign = 1;
	}
	else if (!strcmp(argv[1], "clean")) {
		sign = 2;
	}
	else
		netconn_usage(argv[0]);

	devfd = open(pot_mtd_dev, O_RDWR | O_SYNC);
	if (0 > devfd) {
		printf("netconn: open mtd POT error!\n");
		return -1;
	}
	lseek(devfd, NETCONN_POSTION, SEEK_SET);
	read(devfd, current_con, sizeof(current_con));
	close(devfd);
	
	if (0 == sign) {								//get
		if (!memcmp(nocon, current_con, sizeof(current_con))){
			printf("Ever connected to Internet (Y/N): No\n");
			system("echo No > /tmp/POT_netconn");
		}
		else{
			printf("Ever connected to Internet (Y/N): Yes\n");
			system("echo Yes > /tmp/POT_netconn");
		}
	} 
	else{
		if (1 == sign) {							//set
			if (memcmp(nocon, current_con, sizeof(current_con))) {	
				printf("Ever connected to Internet (Y/N): Yes\n");
			} 
			else {
				res_con[0] = 0x00;
       			res_con[1] = 0x00;
				
				devfd = open(pot_mtd_dev, O_RDWR | O_SYNC);
				if (0 > devfd) {
					printf("netconn: open mtd POT error!\n");
					return -1;
				}
       			lseek(devfd, NETCONN_POSTION, SEEK_SET);
       			write(devfd, res_con, sizeof(res_con));
				close(devfd);

        		printf("Ever connected to Internet (Y/N): Yes\n");
        	}
			system("echo Yes > /tmp/POT_netconn");
		} 
		else {										//clean
			res_con[0] = 0xff;
       		res_con[1] = 0xff;
			
			devfd = open(pot_mtd_dev, O_RDWR | O_SYNC);
			if (0 > devfd) {
				printf("netconn: open mtd POT error!\n");
				return -1;
			}
			lseek(devfd, NETCONN_POSTION, SEEK_SET);
			write(devfd, res_con, sizeof(res_con));
			close(devfd);
			
			printf("Ever connected to Internet (Y/N): No\n");
			system("echo No > /tmp/POT_netconn");
		}
	}
    
	return 0;
}
