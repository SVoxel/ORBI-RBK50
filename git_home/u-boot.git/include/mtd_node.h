#ifndef _NODE_INFO
#define _NODE_INFO

/*
 * Info we use to search for a flash node in DTB.
 */
struct node_info {
	const char *compat;	/* compatible string */
	int type;		/* mtd flash type */
#if defined(CONFIG_HW29764958P0P128P512P4X4P4X4PCASCADE) || \
    defined(CONFIG_HW29765257P0P128P256P3X3P4X4)
	int idx;
#endif
};
#endif
