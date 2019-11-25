# A long time ago, far, far away, under Solaris, you needed to
#    CFLAGS += -xO2 -Xc
#    LDLIBS += -lnsl -lsocket
# To cross-compile
#    CC = arm-linux-gcc
# To use clang
#    CC = clang
# To check for lint
#    CFLAGS += -Wpointer-arith -Wcast-align -Wcast-qual -Wshadow -Wundef \
#     -Waggregate-return -Wnested-externs -Winline -Wwrite-strings \
#     -Wstrict-prototypes -Wmissing-prototypes -pedantic

# This was old-school networking code, making the traditional cast between
# struct sockaddr* and struct sockaddr_in*.  Thus a modern gcc needed:
#CFLAGS += -fno-strict-aliasing
# but as of ntpclient-2015, I cleaned up those casts enough to make both
# gcc-4.9.2 and clang-3.5.0 happy without it.

PREFIX?=/
BIN_DIR?=$(PREFIX)/usr/sbin

#CFLAGS += -std=c99  # should also still work with -std=c89
#CFLAGS += -D_POSIX_C_SOURCE=199309 -D_BSD_SOURCE
CFLAGS += -W -Wall  # -W is spelled -Wextra these days, but -W is stilli
                    # valid and works with older compilers.
CFLAGS += -O2
CFLAGS += -DPRECISION_SIOCGSTAMP
CFLAGS += -DENABLE_DEBUG
#CFLAGS += -DENABLE_REPLAY
CFLAGS += -DENABLE_BOOT_RELAY
CFLAGS += -DNETGEAR_DAYLIGHT_SAVING_TIME
# CFLAGS += -DUSE_OBSOLETE_GETTIMEOFDAY

LOADLIBES += -lrt -lconfig

all: ntpclient

test: ntpclient
	./ntpclient -d -r <test.dat

ntpclient: ntpclient.o phaselock.o

ntpclient.o phaselock.o: ntpclient.h dniconfig.h

adjtimex: adjtimex.o

install: all
	install -d -m0755 $(BIN_DIR)
	install -m0755 ./ntpclient $(BIN_DIR)

clean:
	rm -f ntpclient adjtimex *.o
