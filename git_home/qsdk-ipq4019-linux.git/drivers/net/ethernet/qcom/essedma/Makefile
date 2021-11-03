#
## Makefile for the Qualcomm Atheros ethernet edma driver
#

KBUILD_CFLAGS := $(filter-out -O%,$(KBUILD_CFLAGS)) -O3

obj-$(CONFIG_ESSEDMA) += essedma.o

essedma-objs := edma_axi.o edma.o edma_ethtool.o
