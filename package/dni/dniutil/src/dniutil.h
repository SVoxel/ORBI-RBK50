#ifndef _DNIUTIL_H_
#define _DNIUTIL_H_

/* 
  * Copyright (C) 2007-2008 Delta Networks Inc. 
  */
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <stdarg.h>

#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/un.h>
#include <unistd.h>
#include <sys/signal.h>

struct devtype_v1v2 {
	int DevTypev1;
	char *DevTypev2Name;
};

extern int convert_devtype_v1tov2name(int old, char *new_type, int new_type_len);
extern int convert_devtype_v2nametov1(char *new_type_name);
extern int get_fingtype_by_fingtypeid(char *type_id, char *type);
extern int find_fing_type(char *type);

#endif

