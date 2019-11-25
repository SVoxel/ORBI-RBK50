#This target is to ensure accidental execution of Makefile as a bash script will not execute commands like rm in unexpected directories and exit gracefully.
.prevent_execution:
	exit 0

CC = gcc

#remove @ for no make command prints

CURRENT_DIR = $(shell pwd)

AWS_IOT_INCLUDE_DIRS += -I $(CURRENT_DIR)/include
AWS_IOT_INCLUDE_DIRS += -I $(CURRENT_DIR)/platform/linux/mbedtls
#AWS_IOT_INCLUDE_DIRS += -I $(CURRENT_DIR)/external_libs/jsmn
AWS_IOT_INCLUDE_DIRS += -I $(CURRENT_DIR)/platform/linux/common
AWS_IOT_INCLUDE_DIRS += -I $(CURRENT_DIR)/external_libs/mbedTLS/include
AWS_IOT_INCLUDE_DIRS += -I $(CURRENT_DIR)


CFLAGS += -Wall -Wunused -g -O2


all : subscribe_publish_sample

SHADOW_SAMPLE_DIR = $(CURRENT_DIR)/samples/linux/shadow_sample
SHADOW_SAMPLE_CONSOLE_ECHO_DIR = $(CURRENT_DIR)/samples/linux/shadow_sample_console_echo
SUBSCRIBE_PUBLISH_SAMPLE_DIR = $(CURRENT_DIR)/samples/linux/subscribe_publish_sample



subscribe_publish_sample:
	$(MAKE) -C $(SUBSCRIBE_PUBLISH_SAMPLE_DIR) 

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	$(MAKE) -C $(SHADOW_SAMPLE_DIR) clean
#all %::
#	$(MAKE) -C $(SHADOW_SAMPLE_DIR) $@
#	$(MAKE) -C $(SHADOW_SAMPLE_CONSOLE_ECHO_DIR) $@
#	$(MAKE) -C $(SUBSCRIBE_PUBLISH_SAMPLE_DIR) $@
