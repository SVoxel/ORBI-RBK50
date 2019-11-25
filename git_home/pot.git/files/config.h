#ifndef __CONFIG_H_
#define __CONFIG_H_

#define POT_MTD			"/dev/mmcblk0p15"
#define POT_FILENAME		"/tmp/pot_value"

#define POT_MAX_VALUE	4320		/* 4320 minutes */
#define POT_RESOLUTION	1		/* minute */
#define POT_PORT	3333		/* potval listen this port */
#define NTPTIME_POSTION 2048
#define STAMAC_POSTION (2048 + 4)
#define NTPTIME_POSTION_BYINT (2048/4)
#define SUPPORT_DNITOOLBOX 1

#endif
