#
#   Copyright (C) 2011 Delta Networks Inc.
#

CC = gcc

FILES = base64.o main.o md5.o phglobal.o phsocket.o phupdate.o \
		blowfish.o generate.o log.o

CFLAGS += -Wall -Wunused -g -O2

all : phddns

phddns : $(FILES)
	$(CC) $(CFLAGS) $(FILES) -o $@ $(EXTRA_LDFLAGS) $(LDFLAGS) -lconfig
	@echo "make $@ finished on `date`"

%.o : %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f *.o
	rm -f phddns
