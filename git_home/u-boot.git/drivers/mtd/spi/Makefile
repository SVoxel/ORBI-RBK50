#
# (C) Copyright 2006
# Wolfgang Denk, DENX Software Engineering, wd@denx.de.
#
# See file CREDITS for list of people who contributed to this
# project.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#

include $(TOPDIR)/config.mk

LIB	:= $(obj)libspi_flash.o

ifdef CONFIG_SPL_BUILD
COBJS-$(CONFIG_SPL_SPI_LOAD)	+= spi_spl_load.o
endif

COBJS-$(CONFIG_SPI_FLASH)	+= spi_flash.o
COBJS-$(CONFIG_SPI_FLASH_ATMEL)	+= atmel.o
COBJS-$(CONFIG_SPI_FLASH_EON)	+= eon.o
COBJS-$(CONFIG_SPI_FLASH_MACRONIX)	+= macronix.o
COBJS-$(CONFIG_SPI_FLASH_SPANSION)	+= spansion.o
COBJS-$(CONFIG_SPI_FLASH_SST)	+= sst.o
COBJS-$(CONFIG_SPI_FLASH_STMICRO)	+= stmicro.o
#COBJS-$(CONFIG_SPI_FLASH_WINBOND)	+= winbond.o
COBJS-$(CONFIG_HW29764958P0P128P512P3X3P4X4) += winbond_hw29764958p0p128p512p3x3p4x4.o
COBJS-$(CONFIG_HW29764958P0P128P512P4X4P4X4PCASCADE) += winbond_hw29764958p0p128p512p4x4p4x4pcascade.o
COBJS-$(CONFIG_HW29765257P0P128P256P3X3P4X4) += winbond_hw29765257p0p128p256p3x3p4x4.o
COBJS-$(CONFIG_HW29764958P0P128P512P4X4P4X4PXDSL) += winbond_hw29764958p0p128p512p4x4p4x4pxdsl.o
COBJS-$(CONFIG_HW29765265P16P0P256P2X2P2X2) += winbond_hw29765265p16p0p256p2x2p2x2.o
COBJS-$(CONFIG_HW29765285P16P0P256) += winbond_hw29765285p16p0p256.o
COBJS-$(CONFIG_HW29765285P16P0P128) += winbond_hw29765285p16p0p128.o
COBJS-$(CONFIG_HW29765352P32P4000P512P2X2P2X2P4X4) += winbond_hw29765352p32p4000p512p2x2p2x2p4x4.o
COBJS-$(CONFIG_SPI_FLASH_GIGA)	+= giga.o
COBJS-$(CONFIG_SPI_FRAM_RAMTRON)	+= ramtron.o
COBJS-$(CONFIG_SPI_M95XXX) += eeprom_m95xxx.o
COBJS-$(CONFIG_HW29765265P16P0P256P2X2P2X2) += spi_nand.o
COBJS-$(CONFIG_HW29765265P16P0P256P2X2P2X2) += spi_nor_generic.o
COBJS-$(CONFIG_HW29765285P16P0P256) += spi_nand.o
COBJS-$(CONFIG_HW29765285P16P0P128) += spi_nand.o
COBJS-$(CONFIG_HW29765285P16P0P256) += spi_nor_generic.o
COBJS-$(CONFIG_HW29765285P16P0P128) += spi_nor_generic.o
COBJS-$(CONFIG_HW29765352P32P4000P512P2X2P2X2P4X4) += spi_nand.o
COBJS-$(CONFIG_HW29765352P32P4000P512P2X2P2X2P4X4) += spi_nor_generic.o

COBJS	:= $(COBJS-y)
SRCS	:= $(COBJS:.o=.c)
OBJS	:= $(addprefix $(obj),$(COBJS))

all:	$(LIB)

$(LIB): $(obj).depend $(OBJS)
	$(call cmd_link_o_target, $(OBJS))

#########################################################################

# defines $(obj).depend target
include $(SRCTREE)/rules.mk

sinclude $(obj).depend

#########################################################################
