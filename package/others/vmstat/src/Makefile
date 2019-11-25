#
#	Copyright (C) 2007-2008 Delta Networks Inc.
#
CC = gcc

all: vmstat

CFLAGS += -Wall

%.o: %.c
	$(CC) $(CFLAGS) -c $<

vmstat: vmstat.o version.o sysinfo.o
	$(CC) -o $@ $^

clean:
	rm -f *.o vmstat
