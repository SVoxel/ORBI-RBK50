VPATH = ../src

#CC = gcc
#LD = ld
# CFLAGS += $(TARGET_CFLAGS)
#LDFLAGS = 

OS_LAYER = osl-linux.c

all: lld2d lld2test

include ../src/common.mk

depend:
	$(CC) $(CFLAGS) -M $(DCFILES) >.depend
	$(CC) $(CFLAGS) -M $(TCFILES) >>.depend

-include .depend
