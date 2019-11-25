/*
 * ntpclient.c - NTP client
 *
 * Copyright (C) 1997, 1999, 2000, 2003, 2006, 2007, 2010, 2015  Larry Doolittle  <larry@doolittle.boa.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License (Version 2,
 *  June 1991) as published by the Free Software Foundation.  At the
 *  time of writing, that license was published by the FSF with the URL
 *  http://www.gnu.org/copyleft/gpl.html, and is incorporated herein by
 *  reference.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  Possible future improvements:
 *      - Write more documentation  :-(
 *      - Support leap second processing
 *      - Support IPv6
 *      - Support multiple (interleaved) servers
 *
 *  Compile with -DPRECISION_SIOCGSTAMP if your machine really has it.
 *  Older kernels (before the tickless era, pre 3.0?) only give an answer
 *  to the nearest jiffy (1/100 second), not so interesting for us.
 *
 *  If the compile gives you any flak, check below in the section
 *  labelled "XXX fixme - non-automatic build configuration".
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>     /* gethostbyname */
#include <arpa/inet.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <syslog.h>
#include <fcntl.h>
#include <net/if.h>
#ifdef PRECISION_SIOCGSTAMP
#include <sys/ioctl.h>
#endif
#ifdef USE_OBSOLETE_GETTIMEOFDAY
#include <sys/time.h>
#endif

#include "ntpclient.h"
#include "dniconfig.h"

/* Default to the RFC-4330 specified value */
#ifndef MIN_INTERVAL
#define MIN_INTERVAL 15
#endif

#ifdef ENABLE_DEBUG
#define DEBUG_OPTION "d"
int debug=0;
#else
#define DEBUG_OPTION
#endif

#ifdef ENABLE_REPLAY
#define  REPLAY_OPTION   "r"
#else
#define  REPLAY_OPTION
#endif

extern char *optarg;  /* according to man 2 getopt */

/* libconfig.so */
extern char *config_get(char *name);
extern int config_match(char *name, char *match);
extern int config_invmatch(char *name, char *match);

#include <stdint.h>
typedef uint32_t u32;  /* universal for C99 */
/* typedef u_int32_t u32;   older Linux installs? */

/* XXX fixme - non-automatic build configuration */
#ifdef __linux__
#include <sys/utsname.h>
#include <sys/time.h>
#include <sys/timex.h>
#include <netdb.h>
#else
extern struct hostent *gethostbyname(const char *name);
extern int h_errno;
#define herror(hostname) \
	fprintf(stderr,"Error %d looking up hostname %s\n", h_errno,hostname)
#endif
/* end configuration for host systems */

#define JAN_1970        0x83aa7e80      /* 2208988800 1970 - 1900 in seconds */
#define NTP_PORT (123)
#define DAY_TIME 86400
#define NETGEAR_PERIOD 20

/* How to multiply by 4294.967296 quickly (and not quite exactly)
 * without using floating point or greater than 32-bit integers.
 * If you want to fix the last 12 microseconds of error, add in
 * (2911*(x))>>28)
 */
#define NTPFRAC(x) ( 4294*(x) + ( (1981*(x))>>11 ) )

/* The reverse of the above, needed if we want to set our microsecond
 * clock (via clock_settime) based on the incoming time in NTP format.
 * Basically exact.
 */
#define USEC(x) ( ( (x) >> 12 ) - 759 * ( ( ( (x) >> 10 ) + 32768 ) >> 16 ) )

/* Converts NTP delay and dispersion, apparently in seconds scaled
 * by 65536, to microseconds.  RFC-1305 states this time is in seconds,
 * doesn't mention the scaling.
 * Should somehow be the same as 1000000 * x / 65536
 */
#define sec2u(x) ( (x) * 15.2587890625 )

struct ntptime {
	unsigned int coarse;
	unsigned int fine;
};

struct ntp_control {
	u32 time_of_send[2];
	int live;
	int set_clock;   /* non-zero presumably needs root privs */
	int probe_count;
	int cycle_time;
	int goodness;
	int cross_check;
	char serv_addr[4];
};

/* prototypes for some local routines */
static void send_packet(int usd, u32 time_sent[2]);
static int rfc1305print(u32 *data, struct ntptime *arrival, struct ntp_control *ntpc, int *error);
/* static void udp_handle(int usd, char *data, int data_len, struct sockaddr *sa_source, int sa_len); */

#ifdef ENABLE_BOOT_RELAY
#define BOOT_RELAY_OPTION "y"                  // add an option to force to do ntp boot  relay 
int boot_relay=0;
#else
#define BOOT_RELAY_OPTION
#endif

int ap_mode = 0;
char wan_proto[16] = {0};
char *wan_ifname = NULL;

char time_zone[8] = {0};
#ifdef NETGEAR_DAYLIGHT_SAVING_TIME
#define DST_OPTION "e:"
int dst_flag = 0;
#else
#define DST_OPTION
#endif

#define PPP_STATUS	"/etc/ppp/ppp0-status"
#define PPP1_STATUS      "/etc/ppp/pppoe1-status"
#define BPA_STATUS	"/tmp/bpa_info"
#define CABLE_FILE	"/tmp/port_status"
#define DSL_CABLE_FILE  "/tmp/dsl_port_status"

static struct in_addr get_ipaddr(char *ifname)
{
	int fd;
	struct ifreq ifr;
	struct in_addr pa;

	pa.s_addr = 0;
	fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (fd < 0)
		return pa;

	memset(&ifr, 0, sizeof(ifr));
	ifr.ifr_addr.sa_family = AF_INET;
	strcpy(ifr.ifr_name, ifname);
	if (ioctl(fd, SIOCGIFADDR, &ifr) == 0)
		pa = ((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr;
	close(fd);

	return pa;
}

/* '\0' means read failed */
static char readc(char *file)
{
	int fd;
	char value;

	fd = open(file, O_RDONLY, 0666);
	if (fd < 0)
		return 0;
	if (read(fd, &value, 1) != 1)
		value = 0;
	close(fd);

	return value;
}

/* DHCP / StaticIP ... */
static inline int eth_up(void)
{
	return readc(CABLE_FILE) == '1';
}

/* DSL-DHCP / DSL-StaticIP ... */
static inline int dsl_up(void)
{
	return readc(DSL_CABLE_FILE) == '1';
}

/* It is ONLY used for PPPoE/PPTP mode. */
static inline int ppp_up(void)
{
	return readc(PPP_STATUS) == '1';
}

/* It is ONLY used for mulpppoe mode. */
static inline int ppp_up_mul(void)
{
        return readc(PPP1_STATUS) == '1';
}

/* 1). `up time: %lu`; 2). `down time: %lu` */
static inline int bpa_up(void)
{
	return readc(BPA_STATUS) == 'u';
}

/*under ap mode, wan_ifname is br0, wan_proto is dhcp*/
static inline int apmode_up(void)
{
	return ap_mode == 1;
}

static int net_verified(void)
{
	int alive;

	if (!strcmp(wan_proto, "pppoe") ||!strcmp(wan_proto, "pptp") || !strcmp(wan_proto, "pppoa") || !strcmp(wan_proto, "ipoa")) {
		alive = ppp_up();
	} else if (!strcmp(wan_proto, "bigpond")) {
		alive = bpa_up();
	} else if (!strcmp(wan_proto, "mulpppoe1")) {
		alive = ppp_up_mul();
	} else {
		alive = eth_up()||dsl_up()||apmode_up();
	}

	return alive;
}

int wan_conn_up(void)
{
	int alive;
	struct in_addr ip;

	alive = net_verified();
	if (alive == 0)
		ip.s_addr = 0;
	else
		ip = get_ipaddr(wan_ifname);

	return ip.s_addr != 0;
}

#ifdef NETGEAR_DAYLIGHT_SAVING_TIME
void daylight_saving_setting(void)
{
	time_t now;
	struct tm *tm;
	char date_buf[128];
	time(&now);

#ifdef SUPPORT_ORBI_BASE
	/*just fot traffic meter when time change*/
	if(!strcmp(config_get("endis_traffic"), "1")){
		system("/sbin/cmd_traffic_meter stop");
		system("/sbin/cmd_traffic_meter start");
	}
#endif
	/*the config time_zone includes the daylight saving time offset, so DUT will get the correct locale time by TZ*/
	setenv("TZ", time_zone, 1);
	tm = localtime(&now);
	sprintf(date_buf, "date -s %.2d%.2d%.2d%.2d%d", tm->tm_mon+1, tm->tm_mday, tm->tm_hour, tm->tm_min, tm->tm_year+1900);
	system(date_buf);
}
#endif

/*
  * [NETGEAR SPEC V1.6] 8.6 NTP:
  *
  * NETGEAR NTP Servers
  *	time-a.netgear.com
  *	time-b.netgear.com
  *	time-c.netgear.com
  *	time-d.netgear.com
  *	time-e.netgear.com
  * 	time-f.netgear.com
  *	time-g.netgear.com
  *	time-h.netgear.com
  *
  * NETGEAR NTP Server Assignments
  * The primary and secondary Netgear NTP servers will be selected based upon
  * the user-selected time zone.
  */
struct server_struct
{
	char *primary;
	char *secondary;
};

void select_ntp_servers(char **primary, char **secondary)
{
	char *p;
	int tmzone = 0;

	static struct server_struct ntpsvrs[] = {
		/*00 ~ 02: GMT+0,1,2	Greenwich, Amsterdam, Athens */
		{ "time-g.netgear.com", "time-h.netgear.com" },
		{ "time-g.netgear.com", "time-h.netgear.com" },
		{ "time-g.netgear.com", "time-h.netgear.com" },

		/* 03 ~ 05: GMT+3,4,5	Baghdad, Abu Dhabi, Ekaterinaburg */
		{ "time-f.netgear.com", "time-g.netgear.com" },
		{ "time-f.netgear.com", "time-g.netgear.com" },
		{ "time-f.netgear.com", "time-g.netgear.com" },

		/* 06 ~ 08: GMT+6,7,8	Almaty, Bangkok, Beijing */
		{ "time-e.netgear.com", "time-f.netgear.com" },
		{ "time-e.netgear.com", "time-f.netgear.com" },
		{ "time-e.netgear.com", "time-f.netgear.com" },

		/* 09 ~ 13: GMT+9,10,11,12,13	Tokyo, Brisbane, Solomon Islands */
		{ "time-d.netgear.com", "time-e.netgear.com" },
		{ "time-d.netgear.com", "time-e.netgear.com" },
		{ "time-d.netgear.com", "time-e.netgear.com" },
		{ "time-d.netgear.com", "time-e.netgear.com" },
		{ "time-d.netgear.com", "time-e.netgear.com" },

		/* 14 ~ 16: GMT-1,2,3	Azores, Mid-Atlantic, Brazil */
		{ "time-h.netgear.com", "time-a.netgear.com" },
		{ "time-h.netgear.com", "time-a.netgear.com" },
		{ "time-h.netgear.com", "time-a.netgear.com" },

		/* 17 ~ 19: GMT-4,5,6	Canada, USA/Eastern, USA/Central */
		{ "time-a.netgear.com", "time-b.netgear.com" },
		{ "time-a.netgear.com", "time-b.netgear.com" },
		{ "time-a.netgear.com", "time-b.netgear.com" },

		/* 20 ~ 22: GMT-7,8,9	USA/Mountain, USA/Pacific, Alaska */
		{ "time-b.netgear.com", "time-c.netgear.com" },
		{ "time-b.netgear.com", "time-c.netgear.com" },
		{ "time-b.netgear.com", "time-c.netgear.com" },

		/* 23 ~ 25: GMT-10,11,12	Hawaii, Samoa, Eniwetok */
		{ "time-c.netgear.com", "time-d.netgear.com" },
		{ "time-c.netgear.com", "time-d.netgear.com" },
		{ "time-c.netgear.com", "time-d.netgear.com" },
	};

	/*
	  *  The config data is opposite with the real time zone value, so ...
	  * [GMT-0 --> 00] 
	  * [GMT+1 ~ +12 --> 14 ~ 25]
	  * [GMT-1 ~ -13 --> 1 ~ 13 ]
	  */
	p = time_zone;
	if (strncmp(p, "GMT", 3) == 0) {
		p += 3;
		if (strcmp(p, "-0") == 0)
			tmzone = 0;
		else if (*p == '-')
			tmzone = atoi(++p);
		else
			tmzone = 13 + atoi(++p);
	} else {
		p = 0;
	}

	printf("time zone index is : %d\n", tmzone);
	if (tmzone < 0 || tmzone > 25)
		tmzone = 0;

	*primary = ntpsvrs[tmzone].primary;
	*secondary = ntpsvrs[tmzone].secondary;
}

void apply_settings(void)
{

	char cmd[128];
	char *pid_file = "/tmp/run/syslogd.pid";
	/* touch a flag file for Lighting LED */
	system("[ -f /tmp/led_ntp_updated ] || { "
			"touch /tmp/led_ntp_updated; "
			"}");
	if (access(pid_file,F_OK) == 0){
		sprintf(cmd,"kill -USR1 $(cat %s)",pid_file);
		system(cmd);
		sleep(1);
	}
	syslog(LOG_WARNING, "[Time synchronized with NTP server]");

	/* log the first entry */
	system("[ -f /tmp/ntp_updated ] || touch /tmp/ntp_updated");

#ifdef NETGEAR_DAYLIGHT_SAVING_TIME
	/* check the daylight saving time*/
	if (dst_flag == 1)
		daylight_saving_setting();
#endif

	/*
	 * When time updates, and selects "Per Schedule" for "Block Sites" && "Block Services",
	 * generate the crond's schedule file again.
	 */
	if (config_match("block_skeyword", "1") || config_match("blockserv_ctrl", "1")){
		system("/sbin/cmdsched");
		system("firewall.sh start");
	}

	/* Fixed Bug 23259, when time updates,it must check whether now
	 * should turn off WIFI according WIFI Schedule.
	 */
	if (config_match("wladv_schedule_enable", "1")) {
		system("/sbin/cmdsched");
		system("/sbin/cmdsched_wlan_status 11g");
		if (config_match("wlg_onoff_sched", "1")){
			#if WLAN_COMMON_SUPPORT
			system("wlan schedule 11g off");
			#else
			system("/etc/ath/wifi_schedule 11g off");
			#endif
		}
		else if (config_match("wlg_onoff_sched", "0")){
			#if WLAN_COMMON_SUPPORT
			system("wlan schedule 11g on");
			#else
			system("/etc/ath/wifi_schedule 11g on");
			#endif
		}
	}

	if (config_match("wladv_schedule_enable_a", "1")) {
		system("/sbin/cmdsched_wlan_status 11a");
		if (config_match("wla_onoff_sched", "1")) {
			#if WLAN_COMMON_SUPPORT
			system("wlan schedule 11a off");
			#else
			system("/etc/ath/wifi_schedule 11a off");
			#endif
		}
	}

	if (config_match("wladv_schedule_enable_a", "1")){
		system("/sbin/cmdsched_wlan_status 11a");
		if (config_match("wla_onoff_sched", "1")){
			#if WLAN_COMMON_SUPPORT
			system("wlan schedule 11a off");
			#else
			system("/etc/ath/wifi_schedule 11a off");
			#endif
		}
		else if (config_match("wla_onoff_sched", "0")){
			#if WLAN_COMMON_SUPPORT
			 system("wlan schedule 11a on");
			#else
			 system("/etc/ath/wifi_schedule 11a on");
			#endif
		}
	}
	/* do corresponding actions in ntp_updated once updating the time */
	system("ntp_updated");
}

static int get_current_freq(void)
{
	/* OS dependent routine to get the current value of clock frequency.
	 */
#ifdef __linux__
	struct timex txc;
	txc.modes=0;
	if (adjtimex(&txc) < 0) {
		perror("adjtimex");
		exit(1);
	}
	return txc.freq;
#else
	return 0;
#endif
}

static int set_freq(int new_freq)
{
	/* OS dependent routine to set a new value of clock frequency.
	 */
#ifdef __linux__
	struct timex txc;
	txc.modes = ADJ_FREQUENCY;
	txc.freq = new_freq;
	if (adjtimex(&txc) < 0) {
		perror("adjtimex");
		exit(1);
	}
	return txc.freq;
#else
	return 0;
#endif
}

static void set_time(struct ntptime *new)
{
#ifndef USE_OBSOLETE_GETTIMEOFDAY
	/* POSIX 1003.1-2001 way to set the system clock
	 */
	struct timespec tv_set;
	/* it would be even better to subtract half the slop */
	tv_set.tv_sec  = new->coarse - JAN_1970;
	/* divide xmttime.fine by 4294.967296 */
	tv_set.tv_nsec = USEC(new->fine)*1000;
	if (clock_settime(CLOCK_REALTIME, &tv_set)<0) {
		perror("clock_settime");
		exit(1);
	}
	if (debug) {
		printf("set time to %lu.%.9lu\n", tv_set.tv_sec, tv_set.tv_nsec);
	}
#else
	/* Traditional Linux way to set the system clock
	 */
	struct timeval tv_set;
	/* it would be even better to subtract half the slop */
	tv_set.tv_sec  = new->coarse - JAN_1970;
	/* divide xmttime.fine by 4294.967296 */
	tv_set.tv_usec = USEC(new->fine);
	if (settimeofday(&tv_set,NULL)<0) {
		perror("settimeofday");
		exit(1);
	}
	if (debug) {
		printf("set time to %lu.%.6lu\n", tv_set.tv_sec, tv_set.tv_usec);
	}
#endif
}

static void ntpc_gettime(u32 *time_coarse, u32 *time_fine)
{
#ifndef USE_OBSOLETE_GETTIMEOFDAY
	/* POSIX 1003.1-2001 way to get the system time
	 */
	struct timespec now;
	clock_gettime(CLOCK_REALTIME, &now);
	*time_coarse = now.tv_sec + JAN_1970;
	*time_fine   = NTPFRAC(now.tv_nsec/1000);
#else
	/* Traditional Linux way to get the system time
	 */
	struct timeval now;
	gettimeofday(&now, NULL);
	*time_coarse = now.tv_sec + JAN_1970;
	*time_fine   = NTPFRAC(now.tv_usec);
#endif
}

static void send_packet(int usd, u32 time_sent[2])
{
	u32 data[12];
#define LI 0
#define VN 3
#define MODE 3
#define STRATUM 0
#define POLL 4
#define PREC -6

	if (debug) fprintf(stderr,"Sending ...\n");
	if (sizeof data != 48) {
		fprintf(stderr,"size error\n");
		return;
	}
	memset(data, 0, sizeof data);
	data[0] = htonl (
		( LI << 30 ) | ( VN << 27 ) | ( MODE << 24 ) |
		( STRATUM << 16) | ( POLL << 8 ) | ( PREC & 0xff ) );
	data[1] = htonl(1<<16);  /* Root Delay (seconds) */
	data[2] = htonl(1<<16);  /* Root Dispersion (seconds) */
	ntpc_gettime(time_sent, time_sent+1);
	data[10] = htonl(time_sent[0]); /* Transmit Timestamp coarse */
	data[11] = htonl(time_sent[1]); /* Transmit Timestamp fine   */
	send(usd,data,48,0);
}

static void get_packet_timestamp(int usd, struct ntptime *udp_arrival_ntp)
{
#ifdef PRECISION_SIOCGSTAMP
	struct timeval udp_arrival;
	if ( ioctl(usd, SIOCGSTAMP, &udp_arrival) < 0 ) {
		perror("ioctl-SIOCGSTAMP");
		ntpc_gettime(&udp_arrival_ntp->coarse, &udp_arrival_ntp->fine);
	} else {
		udp_arrival_ntp->coarse = udp_arrival.tv_sec + JAN_1970;
		udp_arrival_ntp->fine   = NTPFRAC(udp_arrival.tv_usec);
	}
#else
	(void) usd;  /* not used */
	ntpc_gettime(&udp_arrival_ntp->coarse, &udp_arrival_ntp->fine);
#endif
}

static int check_source(int data_len, struct sockaddr_in *sa_in, unsigned int sa_len, struct ntp_control *ntpc)
{
	struct sockaddr *sa_source = (struct sockaddr *) sa_in;
	(void) sa_len;  /* not used */
	if (debug) {
		printf("packet of length %d received\n",data_len);
		if (sa_source->sa_family==AF_INET) {
			printf("Source: INET Port %d host %s\n",
				ntohs(sa_in->sin_port),inet_ntoa(sa_in->sin_addr));
		} else {
			printf("Source: Address family %d\n",sa_source->sa_family);
		}
	}
	/* we could check that the source is the server we expect, but
	 * Denys Vlasenko recommends against it: multihomed hosts get it
	 * wrong too often. */
#if 0
	if (memcmp(ntpc->serv_addr, &(sa_in->sin_addr), 4)!=0) {
		return 1;  /* fault */
	}
#else
	(void) ntpc; /* not used */
#endif
	if (NTP_PORT != ntohs(sa_in->sin_port)) {
		return 1;  /* fault */
	}
	return 0;
}

static double ntpdiff( struct ntptime *start, struct ntptime *stop)
{
	int a;
	unsigned int b;
	a = stop->coarse - start->coarse;
	if (stop->fine >= start->fine) {
		b = stop->fine - start->fine;
	} else {
		b = start->fine - stop->fine;
		b = ~b;
		a -= 1;
	}

	return a*1.e6 + b * (1.e6/4294967296.0);
}

/* Does more than print, so this name is bogus.
 * It also makes time adjustments, both sudden (-s)
 * and phase-locking (-l).
 * sets *error to the number of microseconds uncertainty in answer
 * returns 0 normally, 1 if the message fails sanity checks
 */
static int rfc1305print(u32 *data, struct ntptime *arrival, struct ntp_control *ntpc, int *error)
{
/* straight out of RFC-1305 Appendix A */
	int li, vn, mode, stratum, poll, prec;
	int delay, disp, refid;
	struct ntptime reftime, orgtime, rectime, xmttime;
	double el_time,st_time,skew1,skew2;
	int freq;
#ifdef ENABLE_DEBUG
	const char *drop_reason=NULL;
#endif

#define Data(i) ntohl(((u32 *)data)[i])
	li      = Data(0) >> 30 & 0x03;
	vn      = Data(0) >> 27 & 0x07;
	mode    = Data(0) >> 24 & 0x07;
	stratum = Data(0) >> 16 & 0xff;
	poll    = Data(0) >>  8 & 0xff;
	prec    = Data(0)       & 0xff;
	if (prec & 0x80) prec|=0xffffff00;
	delay   = Data(1);
	disp    = Data(2);
	refid   = Data(3);
	reftime.coarse = Data(4);
	reftime.fine   = Data(5);
	orgtime.coarse = Data(6);
	orgtime.fine   = Data(7);
	rectime.coarse = Data(8);
	rectime.fine   = Data(9);
	xmttime.coarse = Data(10);
	xmttime.fine   = Data(11);
#undef Data

	if (debug) {
	printf("LI=%d  VN=%d  Mode=%d  Stratum=%d  Poll=%d  Precision=%d\n",
		li, vn, mode, stratum, poll, prec);
	printf("Delay=%.1f  Dispersion=%.1f  Refid=%u.%u.%u.%u\n",
		sec2u(delay),sec2u(disp),
		refid>>24&0xff, refid>>16&0xff, refid>>8&0xff, refid&0xff);
	printf("Reference %u.%.6u\n", reftime.coarse, USEC(reftime.fine));
	printf("(sent)    %u.%.6u\n", ntpc->time_of_send[0], USEC(ntpc->time_of_send[1]));
	printf("Originate %u.%.6u\n", orgtime.coarse, USEC(orgtime.fine));
	printf("Receive   %u.%.6u\n", rectime.coarse, USEC(rectime.fine));
	printf("Transmit  %u.%.6u\n", xmttime.coarse, USEC(xmttime.fine));
	printf("Our recv  %u.%.6u\n", arrival->coarse, USEC(arrival->fine));
	}
	el_time=ntpdiff(&orgtime,arrival);   /* elapsed */
	st_time=ntpdiff(&rectime,&xmttime);  /* stall */
	skew1=ntpdiff(&orgtime,&rectime);
	skew2=ntpdiff(&xmttime,arrival);
	freq=get_current_freq();
	if (debug) {
	printf("Total elapsed: %9.2f\n"
	       "Server stall:  %9.2f\n"
	       "Slop:          %9.2f\n",
		el_time, st_time, el_time-st_time);
	printf("Skew:          %9.2f\n"
	       "Frequency:     %9d\n"
	       " day   second     elapsed    stall     skew  dispersion  freq\n",
		(skew1-skew2)/2, freq);
	}

	/* error checking, see RFC-4330 section 5 */
#ifdef ENABLE_DEBUG
#define FAIL(x) do { drop_reason=(x); goto fail;} while (0)
#else
#define FAIL(x) goto fail;
#endif
	if (ntpc->cross_check) {
		if (li == 3) FAIL("LI==3");  /* unsynchronized */
		if (vn < 3) FAIL("VN<3");   /* RFC-4330 documents SNTP v4, but we interoperate with NTP v3 */
		if (mode != 4) FAIL("MODE!=3");
		if (orgtime.coarse != ntpc->time_of_send[0] ||
		    orgtime.fine   != ntpc->time_of_send[1] ) FAIL("ORG!=sent");
		if (xmttime.coarse == 0 && xmttime.fine == 0) FAIL("XMT==0");
		if (delay > 65536 || delay < -65536) FAIL("abs(DELAY)>65536");
		if (disp  > 65536 || disp  < -65536) FAIL("abs(DISP)>65536");
		if (stratum == 0) FAIL("STRATUM==0");  /* kiss o' death */
#undef FAIL
	}

	/* XXX should I do this if debug flag is set? */
	if (ntpc->set_clock) { /* you'd better be root, or ntpclient will exit here! */
		set_time(&xmttime);
	}

	/* Not the ideal order for printing, but we want to be sure
	 * to do all the time-sensitive thinking (and time setting)
	 * before we start the output, especially fflush() (which
	 * could be slow).  Of course, if debug is turned on, speed
	 * has gone down the drain anyway. */
	if (ntpc->live) {
		int new_freq;
		new_freq = contemplate_data(arrival->coarse, (skew1-skew2)/2,
			el_time+sec2u(disp), freq);
		if (!debug && new_freq != freq) set_freq(new_freq);
	}

	if (debug)
		printf("%d %.5d.%.3d  %8.1f %8.1f  %8.1f %8.1f %9d\n",
				arrival->coarse/86400, arrival->coarse%86400,
				arrival->fine/4294967, el_time, st_time,
				(skew1-skew2)/2, sec2u(disp), freq);

	fflush(stdout);
	*error = el_time-st_time;

	return 0;
fail:
#ifdef ENABLE_DEBUG
	printf("%d %.5d.%.3d  rejected packet: %s\n",
		arrival->coarse/86400, arrival->coarse%86400,
		arrival->fine/4294967, drop_reason);
#else
	printf("%d %.5d.%.3d  rejected packet\n",
		arrival->coarse/86400, arrival->coarse%86400,
		arrival->fine/4294967);
#endif
	return 1;
}

int check_valid_ipaddr(char *ip,unsigned int *ip_addr)
{
	*ip_addr = inet_addr(ip);
	if (INADDR_NONE ==* ip_addr || * ip_addr == 0)
		return 0;
	return 1;
}

static int stuff_net_addr(struct in_addr *p, char *hostname)
{
	struct hostent *ntpserver;
	ntpserver=gethostbyname(hostname);
	if (ntpserver == NULL) {
		/* avoid printing: "time-h.netgear.com: Unknown host" */
		/* herror(hostname); */
		return 0;
	}
	if (ntpserver->h_length != 4) {
		/* IPv4 only, until I get a chance to test IPv6 */
		fprintf(stderr,"oops %d\n",ntpserver->h_length);
		return 0;
	}
	memcpy(&(p->s_addr),ntpserver->h_addr_list[0],4);
	return 1;
}

static int setup_receive(int usd, unsigned int interface, unsigned short port)
{
	struct sockaddr_in sa_rcvr;
	memset(&sa_rcvr, 0, sizeof sa_rcvr);
	sa_rcvr.sin_family=AF_INET;
	sa_rcvr.sin_addr.s_addr=htonl(interface);
	sa_rcvr.sin_port=htons(port);
	if(bind(usd,(struct sockaddr *) &sa_rcvr,sizeof sa_rcvr) == -1) {
		perror("bind");
		fprintf(stderr,"could not bind to udp port %d\n",port);
		return 0;
	}
	/* listen(usd,3); this isn't TCP; thanks Alexander! */

	/* Make "usd" close on child process when call system(),
	 * so that the child process will not inherit the parent resource */
	fcntl(usd, F_SETFD, FD_CLOEXEC);

	return 1;
}

static int setup_transmit(int usd, char *host, unsigned short port, struct ntp_control *ntpc)
{
	struct sockaddr_in sa_dest;
	unsigned int ip_addr=0;
	memset(&sa_dest, 0, sizeof sa_dest);
	sa_dest.sin_family=AF_INET;

	/*Spec NTP V2 the input field of the "Set your preferred NTP server"
	 * option shall support both entering*/
	/*an IP address or DNS address*/
	if(check_valid_ipaddr(host,&ip_addr)) {
		sa_dest.sin_addr.s_addr = inet_addr(host);
	} else {
		if (!stuff_net_addr(&(sa_dest.sin_addr), host))
			return 0;
	}

	memcpy(ntpc->serv_addr,&(sa_dest.sin_addr),4); /* XXX asumes IPv4 */
	sa_dest.sin_port=htons(port);
	if (connect(usd,(struct sockaddr *)&sa_dest,sizeof sa_dest)==-1)
		{perror("connect");return 0;}

	return 1;
}

static int primary_loop(int usd, struct ntp_control *ntpc)
{
	fd_set fds;
	struct sockaddr_in sa_xmit_in;
	int i, pack_len, probes_sent, error;
	socklen_t sa_xmit_len;
	struct timeval to;
	struct ntptime udp_arrival_ntp;
	static u32 incoming_word[325];
	int steady_state = 0;
	int sysnc_result=0;
#define incoming ((char *) incoming_word)
#define sizeof_incoming (sizeof incoming_word)

	if (debug) printf("Listening...\n");

	probes_sent=0;
	sa_xmit_len=sizeof sa_xmit_in;
	to.tv_sec=0;
	to.tv_usec=0;
	for (;;) {
		FD_ZERO(&fds);
		FD_SET(usd, &fds);
		i = select(usd+1, &fds, NULL, NULL, &to);  /* Wait on read or error */
		if ((i!=1)||(!FD_ISSET(usd,&fds))) {
			if (i < 0) {
				if (errno != EINTR) perror("select");
				continue;
			}
			if ((to.tv_sec == 0) || (to.tv_sec == ntpc->cycle_time) || (to.tv_sec == DAY_TIME)) {
				if (steady_state != 1 && probes_sent >= ntpc->probe_count &&
					ntpc->probe_count != 0){
					sysnc_result = 0;
					break;
				}

				steady_state = 0;
				send_packet(usd,ntpc->time_of_send);
				++probes_sent;
				to.tv_sec=ntpc->cycle_time;
				to.tv_usec=0;
			}
			continue;
		}
		pack_len=recvfrom(usd,incoming,sizeof_incoming,0,
		                  (struct sockaddr *) &sa_xmit_in,&sa_xmit_len);
		error = ntpc->goodness;
		if (pack_len<0) {
			perror("recvfrom");
		    /* A query receives no successful response, the retry algorithm must 
			*  wait that random delay period before initiating the first retry query.
			*/
			select(1, NULL, NULL, NULL, &to);
		} else if (pack_len>0 && (unsigned)pack_len<sizeof_incoming){
			get_packet_timestamp(usd, &udp_arrival_ntp);
			if (check_source(pack_len, &sa_xmit_in, sa_xmit_len, ntpc)!=0) continue;
			if (rfc1305print(incoming_word, &udp_arrival_ntp, ntpc, &error)!=0) continue;
			steady_state = 1;
			apply_settings();
			/* udp_handle(usd,incoming,pack_len,&sa_xmit,sa_xmit_len); */
		} else {
			printf("Ooops.  pack_len=%d\n",pack_len);
			fflush(stdout);
		}

		if (steady_state == 1) {
			to.tv_sec = DAY_TIME;
			to.tv_usec = 0;
		} else if ((error < ntpc->goodness && ntpc->goodness != 0) ||
		    (probes_sent >= ntpc->probe_count && ntpc->probe_count != 0)) {
		/* best rollover option: specify -g, -s, and -l.
		 * simpler rollover option: specify -s and -l, which
		 * triggers a magic -c 1 */
			ntpc->set_clock = 0;
			if (!ntpc->live){
				sysnc_result = 0;
				break;
			}
		}
	}
#undef incoming
#undef sizeof_incoming
	return sysnc_result;
}

#ifdef ENABLE_REPLAY
static void do_replay(void)
{
	char line[100];
	int n, day, freq, absolute;
	float sec, el_time, st_time, disp;
	double skew, errorbar;
	int simulated_freq = 0;
	unsigned int last_fake_time = 0;
	double fake_delta_time = 0.0;

	while (fgets(line,sizeof line,stdin)) {
		n=sscanf(line,"%d %f %f %f %lf %f %d",
			&day, &sec, &el_time, &st_time, &skew, &disp, &freq);
		if (n==7) {
			fputs(line,stdout);
			absolute=day*86400+(int)sec;
			errorbar=el_time+disp;
			if (debug) printf("contemplate %u %.1f %.1f %d\n",
				absolute,skew,errorbar,freq);
			if (last_fake_time==0) simulated_freq=freq;
			fake_delta_time += (absolute-last_fake_time)*((double)(freq-simulated_freq))/65536;
			if (debug) printf("fake %f %d \n", fake_delta_time, simulated_freq);
			skew += fake_delta_time;
			freq = simulated_freq;
			last_fake_time = absolute;
			simulated_freq = contemplate_data(absolute, skew, errorbar, freq);
		} else {
			fprintf(stderr,"Replay input error\n");
			exit(2);
		}
	}
}
#endif

static const char *ntp_pid_file = "/tmp/run/ntpclient.pid";
static void save_ntp_pid(void) {
	int pid_fd;
	FILE *pid = NULL;

	if (ntp_pid_file != NULL) {
		unlink(ntp_pid_file);
		pid_fd = open(ntp_pid_file, O_CREAT | O_EXCL | O_WRONLY, 0600);
		if (pid_fd == -1) {
			perror("open ntp_pid_file");
			exit(1);
		}
		else {
			if ((pid = fdopen(pid_fd, "w")) == NULL) {
				perror("open ntp_pid");
				exit(1);
			} else {
				fprintf(pid, "%d\n", (int) getpid());
				fclose(pid);
			}
			close(pid_fd);
		}
	}
}

static void usage(char *argv0)
{
	fprintf(stderr,
	"Usage: %s [-c count]"
#ifdef ENABLE_DEBUG
	" [-d]"
#endif
	" [-f frequency] [-g goodness] -h hostname\n"
	"\t[-i interval] [-l] [-p port] [-q min_delay]"
#ifdef ENABLE_REPLAY
	" [-r]"
#endif
	" [ -w wan_proto] [ -n interface]"
	" [ -e dst_set] [ -z time_zone]"
	" [-s] [-t]\n",
	argv0);
}

int get_random_sport()
{
	FILE *fp;
	char cmd[64];
	int sport;
	int ntp_min_port = 1024;
	int ntp_max_port = 65535;
	int ret;

	while(1) {
		sport = ntp_min_port + rand()%(ntp_max_port - ntp_min_port + 1);
		sprintf(cmd, "netstat -atun |grep %d > /tmp/ntp_sport", sport);
		system(cmd);
		if((fp = fopen("/tmp/ntp_sport", "r"))){
			ret = fgetc(fp);
			fclose(fp);
			if(ret == EOF )
				break;
		}
	}
//	printf("=====random sport%d\n", sport);
	system("rm -f /tmp/ntp_sport ");
	return sport;
}

int main(int argc, char *argv[]) {
	int usd;  /* socket */
	int c;
	/* These parameters are settable from the command line
	   the initializations here provide default behavior */
	unsigned short udp_local_port=0;   /* default of 0 means kernel chooses */
	int initial_freq;             /* initial freq value to use */
	struct ntp_control ntpc;
	int min_interval = 0;
	int max_interval = 0;
	char *hostname=NULL;          /* must be set */
	char *sec_host = "0.0.0.0";
	char *ntps = "0.0.0.0";
	char *manual_ntp = NULL , *manual_ntp_server = NULL;
	char ntp_server[128]={};
	int sysnc_ok =0, change_mode = 0, err;

	struct timeval to;

	unsigned long seed;
	seed = time(0);
	srand(seed);

	/* ntpclient -h "time-g.netgear.com" -b "time-h.netgear.com" -i 15 -m 60 -p 123 -s */
	// use the default values to work correctly
	ntpc.live=0;
	ntpc.set_clock=1;
	ntpc.probe_count=1;           /* default of 0 means loop forever */
	ntpc.cycle_time=MIN_INTERVAL;          /* seconds */
	ntpc.goodness=0;
	ntpc.cross_check=1;

	min_interval = 1;
	max_interval = 60;
	udp_local_port = NTP_PORT;
#ifdef ENABLE_BOOT_RELAY
	FILE *fp = NULL;
	boot_relay = 0;
#endif

	for (;;) {
		c = getopt( argc, argv, "c:" DEBUG_OPTION "b:m:i:w:n:z:" BOOT_RELAY_OPTION DST_OPTION "f:g:h:lp:q:" REPLAY_OPTION "st");
		if (c == EOF) break;
		switch (c) {
			case 'c':
				ntpc.probe_count = atoi(optarg);
				break;
#ifdef ENABLE_DEBUG
			case 'd':
				++debug;
				break;
#endif
			case 'f':
				initial_freq = atoi(optarg);
				if (debug) printf("initial frequency %d\n",
						initial_freq);
				set_freq(initial_freq);
				break;
			case 'g':
				ntpc.goodness = atoi(optarg);
				break;
			case 'h':
				hostname = optarg;
				break;
			case 'l':
				(ntpc.live)++;
				break;
			case 'p':
				udp_local_port = atoi(optarg);
				break;
			case 'q':
				min_delay = atof(optarg);
				break;
#ifdef ENABLE_REPLAY
			case 'r':
				do_replay();
				exit(0);
				break;
#endif
			case 's':
				ntpc.set_clock++;
				break;

			case 't':
				ntpc.cross_check = 0;
				break;

#ifdef ENABLE_BOOT_RELAY
			case 'y':
				boot_relay = 1;
				break;
#endif

			case 'b':
				sec_host = optarg;
				break;
			case 'm':
				max_interval = atoi(optarg);
				break;
			case 'i':
				min_interval = atoi(optarg);
				break;

			case 'w':
				if(strdup(optarg) != NULL)
					strncpy(wan_proto, strdup(optarg), sizeof(wan_proto)-1);
				break;

			case 'n':
				wan_ifname = strdup(optarg);
				break;

			case 'z':
				if(strdup(optarg) != NULL)
					strncpy(time_zone, strdup(optarg), sizeof(time_zone)-1);
				break;

#ifdef NETGEAR_DAYLIGHT_SAVING_TIME
			case 'e':
				dst_flag = atoi(optarg);
				break;
#endif
			default:
				usage(argv[0]);
				exit(1);
		}
	}

	if(time_zone[0] == '\0' && config_get("time_zone"))
		strncpy(time_zone, config_get("time_zone"), sizeof(time_zone)-1);

	if(wan_proto[0] == '\0')
		strncpy(wan_proto, config_get("wan_proto"), sizeof(wan_proto)-1);

	if(wan_ifname == NULL) {
		if (!strcmp(wan_proto, "pppoe") ||!strcmp(wan_proto, "pptp") || !strcmp(wan_proto, "pppoa") || !strcmp(wan_proto, "ipoa")) {
			wan_ifname=PPP_IFNAME;
		} else if (!strcmp(wan_proto, "bigpond")) {
			wan_ifname=NET_IFNAME;
		} else if (!strcmp(wan_proto, "mulpppoe1")) {
			wan_ifname=PPP_IFNAME;
		} else {
			wan_ifname=NET_IFNAME;
		}
	}
	
	manual_ntp=config_get("ntp_server_type");
	 /*When user manually enters the preferred NTP server, the preferred
	  * NTP server shall be set as primary time server and  secondary
	  * host time server is the same ,*/
	if (strcmp(manual_ntp,"1") != 0)
		select_ntp_servers(&hostname, &sec_host);
	else {
		select_ntp_servers(&sec_host, &hostname);
		manual_ntp_server=config_get("manual_ntp_server");
		strcpy(ntp_server,manual_ntp_server);
		sec_host = hostname = ntp_server;
	}

	if (hostname == NULL) {
		usage(argv[0]);
		exit(1);
	}
	printf("Run NTP Client with setting: pri:%s sec:%s\n", hostname ? : "", sec_host ? : "");

	if (strcmp(sec_host, "0.0.0.0") == 0)
		sec_host = hostname;

	if (min_interval > max_interval || min_interval < 0 || max_interval < 0) {
		usage(argv[0]);
		exit(1);
	} else if (max_interval == 0) {
		max_interval = MIN_INTERVAL;
		min_interval = MIN_INTERVAL;
	} else
		ntpc.cycle_time = min_interval + rand()%(max_interval-min_interval+1);
	
	if (!strcmp(wan_ifname, "br0"))
		ap_mode = 1;

	if (debug) {
		printf("Configuration:\n"
			"  -c probe_count       %d\n"
			"  -d (debug)           %d\n"
			"  -h hostname          %s\n"
			"  -b second hostname   %s\n"
			"  -i interval(min)     %d\n"
			"  -m interval(max)     %d\n"
			"  -e dst enable		%d\n"
			"  -z time_zone			%s\n"
			"  -w wan_proto			%s\n"
			"  -p local_port        %d\n"
			"  -s set_clock         %d\n",
			ntpc.probe_count, debug, hostname, sec_host, 
			min_interval, max_interval, dst_flag, time_zone, wan_proto, udp_local_port, ntpc.set_clock);
	} else {
		daemon(1, 1);
	}

	system("[ -f /tmp/ntp_updated ] && rm -f /tmp/ntp_updated");

#ifdef ENABLE_BOOT_RELAY
	if (boot_relay == 0){
		//detect whether the router is in the booting process
		fp=fopen("/tmp/boot_status","r");
		if (fp != NULL){
			boot_relay = 1;
			fclose(fp);
			fp = NULL;
		}
	}
#endif

	if (ntpc.set_clock && !ntpc.live && !ntpc.goodness && !ntpc.probe_count) {
		ntpc.probe_count = 1;
	}

	/* respect only applicable MUST of RFC-4330 */
	if (ntpc.probe_count != 1 && ntpc.cycle_time < MIN_INTERVAL) {
		ntpc.cycle_time = MIN_INTERVAL;
	}

	save_ntp_pid();

	while(1) {
		ntps = (strcmp(ntps, hostname) == 0) ? sec_host : hostname;

	if (debug) {
		printf("Configuration:\n"
		"  -c probe_count %d\n"
		"  -d (debug)     %d\n"
		"  -g goodness    %d\n"
		"  -h ntpserver    %s\n"
		"  -i interval    %d\n"
		"  -l live        %d\n"
		"  -p local_port  %d\n"
		"  -q min_delay   %f\n"
		"  -s set_clock   %d\n"
		"  -x cross_check %d\n",
		ntpc.probe_count, debug, ntpc.goodness,
		ntps, ntpc.cycle_time, ntpc.live, udp_local_port, min_delay,
		ntpc.set_clock, ntpc.cross_check );
	}

	printf("Configuration: NTP server : %s Interval : %d Local port : %d\n", ntps, ntpc.cycle_time, udp_local_port);
	/* Startup sequence */
	if ((usd=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP))==-1) {
		perror ("socket");
		goto cont;
	}

#ifndef SUPPORT_ORBI_SATELITE
		if (!wan_conn_up()
#ifdef SUPPORT_ORBI_BASE
			&& config_match("ap_mode", "0")
			&& config_match("bridge_mode", "0")
#endif
		   ){
			/* printf("The WAN connection is NOT up!\n"); */
			close(usd);
			goto cont;
		}
#endif
#ifdef ENABLE_BOOT_RELAY
		if (boot_relay == 1){
			ntps = "0.0.0.0";
			close(usd);
			goto cont;
		}
#endif

	if (!setup_receive(usd, INADDR_ANY, udp_local_port)
			|| !setup_transmit(usd, ntps, NTP_PORT, &ntpc)) {
		close(usd);
		to.tv_sec = ntpc.cycle_time;
		to.tv_usec = 0;
		select(1, NULL, NULL, NULL, &to);
		goto loop;
	}

	/*The NTP packet must be a server response to a previously issued
	 * query received within a reasonable time window(5 sec) relative to the
	 * request, and the secs time window shall not be include in the 0~60 seconds
	 * interval*/
	ntpc.cycle_time = 5;
	sysnc_ok = primary_loop(usd, &ntpc);

	/*when program is out of primary loop,the NTP server is fail,so delete the file.*/
	system("rm -f /tmp/ntp_updated");

	close(usd);

	loop:
		/* [NETGEAR Spec 12]:Subsequent queries will double the preceding query interval 
		 * until the interval has exceeded the steady state query interval, at which point 
		 * and new random interval between 0.00 and 60.00 seconds is selected and the 
		 * process repeats.
		 */
		if(!sysnc_ok){
//			printf("NTP Sync time stamp fail, will wait %d s\n", ntpc.cycle_time);
			to.tv_sec = ntpc.cycle_time;
			to.tv_usec = 0;
			do {
				err = select(1, NULL, NULL, NULL, &to);
			} while(err < 0 && errno == EINTR);
		}

		/* to avoid the false alarm of ISP blocking port 123 situation
		 * due to internet unstable reasons, the retries shall iterate swithching
		 * between primart and secondary server, and between 123 and non-123 port
		 * No.1 retry to primary server with source port 123
		 * No.2 retry to secondary server with source port 123
		 * No.3 retry to primary server with source port 1077
		 * No.4 retry to secondary server with source port 1077
		 * No.5 retry to primary server with source port 123
		 * No.6 retry to secondary server with source port 123
		 * No.7 retry to primary server with source port 3045
		 * No.8 retry to secondary server with source port 3045
		 * keep iterating*/
		if(strcmp(ntps, hostname))
			change_mode=1;
		else
			change_mode=0;
		/*(1)Scan port range from 1024 to 65535 to know which ports are in use
		 *(2)Random select a non-used port from the range in (1)
		 *(3) Send the next request with the selected port in (2)*/
		if(change_mode || config_match("ntp_server_type", "1")){
			if(udp_local_port == NTP_PORT)
				udp_local_port = get_random_sport();
			else
				udp_local_port = NTP_PORT;
		}

		if ((ntpc.cycle_time * 2) > DAY_TIME)
			ntpc.cycle_time = min_interval + rand()%(max_interval-min_interval+1);
		else
			ntpc.cycle_time = ntpc.cycle_time * 2;
		continue;

	cont:	
		/* [NETGEAR Spec 12]: we will wait randomly calculated period of 0 to 20 seconds 
		 * before issuing the first NTP query upon subsequent power-ons or resets. 
		 */
#ifdef ENABLE_BOOT_RELAY
		if (boot_relay == 1){
			boot_relay = 0;
		}
#endif
		to.tv_sec = rand() % (NETGEAR_PERIOD + 1);
		to.tv_usec = 0;
		select(1, NULL, NULL, NULL, &to);

	}
	
	unlink(ntp_pid_file); /*remove the pid file*/
	return 0;
}
