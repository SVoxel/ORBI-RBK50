#
#	Copyright (C) 2012 Delta Networks Inc.
#
include $(POT_CONF)

CC = gcc

FILES = pot.c excmd.c common.h config.h
TARGET = potd potval ntpst stamac netconn

CFLAGS += -Wall -Wunused -g
LIBMTDPATH = ./../../dni-libmtd
CFLAGS += -Wall -Wunused -g -I $(LIBMTDPATH)
CFLAGS += -DPOT_MTD=$(POT_MTD)
LDFLAGS += -lconfig -L $(LIBMTDPATH) -lmtd


all : $(TARGET)

potd : $(FILES)
	$(CC) $(CFLAGS) $(FILES) -o $@ $(EXTRA_LDFLAGS) $(LDFLAGS)
	@echo "make $@ finished on `date`"

potval: $(FILES)
	$(CC) $(CFLAGS) $(FILES) -o $@ $(EXTRA_LDFLAGS) $(LDFLAGS)
	@echo "make $@ finished on `date`"

ntpst: $(FILES)
	$(CC) $(CFLAGS) $(FILES) -o $@ $(EXTRA_LDFLAGS) $(LDFLAGS)
	@echo "make $@ finished on `date`"

stamac: $(FILES)
	$(CC) $(CFLAGS) $(FILES) -o $@ $(EXTRA_LDFLAGS) $(LDFLAGS)
	@echo "make $@ finished on `date`"

netconn: $(FILES)
	$(CC) $(CFLAGS) $(FILES) -o $@ $(EXTRA_LDFLAGS) $(LDFLAGS)
	@echo "make $@ finished on `date`"

%.o : %.c
	$(CC) $(CFLAGS) -c $<

install:
	$(INSTALL_DIR) $(INS_BIN_DIR) 

	$(INSTALL_BIN) potd $(INS_BIN_DIR)
	$(INSTALL_BIN) potval $(INS_BIN_DIR)
	$(INSTALL_BIN) ntpst $(INS_BIN_DIR)
	$(INSTALL_BIN) stamac $(INS_BIN_DIR)
	$(INSTALL_BIN) netconn $(INS_BIN_DIR)

clean:
	rm -f *.o
	rm -f $(TARGET)
