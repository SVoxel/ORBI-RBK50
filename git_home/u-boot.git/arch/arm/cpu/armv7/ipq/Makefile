# Copyright (c) 2012 The Linux Foundation. All rights reserved.

include $(TOPDIR)/config.mk

LIB	=  $(obj)lib$(SOC).o

SOBJS-y = timer.o
COBJS-y += clock.o
COBJS-y += gpio.o
#COBJS-y += smem.o
COBJS-$(CONFIG_HW29764958P0P128P512P3X3P4X4) += smem_hw29764958p0p128p512p3x3p4x4.o
COBJS-$(CONFIG_HW29764958P0P128P512P4X4P4X4PCASCADE) += smem_hw29764958p0p128p512p4x4p4x4pcascade.o
COBJS-$(CONFIG_HW29765257P0P128P256P3X3P4X4) += smem_hw29765257p0p128p256p3x3p4x4.o
COBJS-$(CONFIG_HW29764958P0P128P512P4X4P4X4PXDSL) += smem_hw29764958p0p128p512p4x4p4x4pxdsl.o
COBJS-y += scm.o
#COBJS-y += cmd_bootipq.o
COBJS-$(CONFIG_HW29764958P0P128P512P3X3P4X4) += cmd_bootipq_hw29764958p0p128p512p3x3p4x4.o
COBJS-$(CONFIG_HW29764958P0P128P512P4X4P4X4PCASCADE) += cmd_bootipq_hw29764958p0p128p512p4x4p4x4pcascade.o
COBJS-$(CONFIG_HW29765257P0P128P256P3X3P4X4) += cmd_bootipq_hw29765257p0p128p256p3x3p4x4.o
COBJS-$(CONFIG_HW29764958P0P128P512P4X4P4X4PXDSL) += cmd_bootipq_hw29764958p0p128p512p4x4p4x4pxdsl.o
ifeq ($(CONFIG_IPQ_APPSBL_DLOAD),y)
COBJS-y += cmd_dumpipq_data.o
endif

SRCS	:= $(SOBJS-y:.o=.S) $(COBJS-y:.o=.c)
OBJS	:= $(addprefix $(obj),$(COBJS-y) $(SOBJS-y))

all:	 $(obj).depend $(LIB)

$(LIB):	$(OBJS)
	$(call cmd_link_o_target, $(OBJS))

#########################################################################

# defines $(obj).depend target
include $(SRCTREE)/rules.mk

sinclude $(obj).depend

#########################################################################

