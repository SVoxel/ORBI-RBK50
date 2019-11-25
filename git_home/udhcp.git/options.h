/* options.h */
#ifndef _OPTIONS_H
#define _OPTIONS_H

#include "packet.h"
#include "config.h"

#define TYPE_MASK	0x0F

enum {
	OPTION_IP=1,
	OPTION_IP_PAIR,
#if defined (RFC3442_121_SUPPORT) || defined (RFC3442_249_SUPPORT)
	OPTION_IP_COMP,
#endif
	OPTION_STRING,
	OPTION_BOOLEAN,
	OPTION_U8,
	OPTION_U16,
	OPTION_S16,
	OPTION_U32,
	OPTION_S32,
	OPTION_6RD
};

#define OPTION_REQ	0x10 /* have the client request this option */
#define OPTION_LIST	0x20 /* There can be a list of 1 or more of these */

#define VENDOR_ADSL_FORUM_ENTERPRISE_NUMBER	3561
#define VENDOR_IDENTIFYING_FOR_GATEWAY		1
#define VENDOR_ENTERPRISE_LEN			4    /* 4 bytes */
#define VENDOR_IDENTIFYING_INFO_LEN		142
#define VENDOR_IDENTIFYING_OPTION_CODE		125
#define VENDOR_OPTION_CODE_OFFSET		0
#define VENDOR_OPTION_LEN_OFFSET		1
#define VENDOR_OPTION_ENTERPRISE_OFFSET		2
#define VENDOR_OPTION_DATA_OFFSET		6
#define VENDOR_OPTION_DATA_LEN			1
#define VENDOR_OPTION_SUBCODE_LEN		1
#define VENDOR_SUBCODE_AND_LEN_BYTES		2
#define VENDOR_GATEWAY_OUI_SUBCODE		4
#define VENDOR_GATEWAY_SERIAL_NUMBER_SUBCODE	5
#define VENDOR_GATEWAY_PRODUCT_CLASS_SUBCODE	6

#define _LB4_deviceOui		"289EFC"
#define _LB4_deviceSerialNum	"NQ2019044010129"
#define _LB4_deviceProductClass	"Livebox 4"
#define OUI_LENGTH		8
#define SN_LENGTH		16
#define PC_LENGTH		10

struct dhcp_option {
	char name[16];
	char flags;
	unsigned char code;
};

extern struct dhcp_option options[];
extern int option_lengths[];

#ifdef	DHCPD_SHOW_CLIENT_OPTIONS
void get_option_codes(struct dhcpMessage *packet, char *options);
#endif
unsigned char *get_option(struct dhcpMessage *packet, int code);
int end_option(unsigned char *optionptr);
int add_option_string(unsigned char *optionptr, unsigned char *string);
int add_simple_option(unsigned char *optionptr, unsigned char code, u_int32_t data);
struct option_set *find_option(struct option_set *opt_list, char code);
void attach_option(struct option_set **opt_list, struct dhcp_option *option, char *buffer, int length);

int createVIoption(int type, char *VIinfo);
#endif
