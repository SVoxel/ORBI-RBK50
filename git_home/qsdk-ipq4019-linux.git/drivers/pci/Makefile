#
# Makefile for the PCI bus specific drivers.
#

KBUILD_CFLAGS := $(filter-out -O%,$(KBUILD_CFLAGS)) -O3

obj-y		+= access.o bus.o probe.o host-bridge.o remove.o pci.o \
			pci-driver.o search.o pci-sysfs.o rom.o setup-res.o \
			irq.o vpd.o setup-bus.o vc.o
obj-$(CONFIG_PROC_FS) += proc.o
obj-$(CONFIG_SYSFS) += slot.o

obj-$(CONFIG_PCI_QUIRKS) += quirks.o

# Build PCI Express stuff if needed
obj-$(CONFIG_PCIEPORTBUS) += pcie/

obj-$(CONFIG_PCI_IOAPIC) += ioapic.o

# Build the PCI Hotplug drivers if we were asked to
obj-$(CONFIG_HOTPLUG_PCI) += hotplug/
ifdef CONFIG_HOTPLUG_PCI
obj-y += hotplug-pci.o
endif

# Build the PCI MSI interrupt support
obj-$(CONFIG_PCI_MSI) += msi.o

# Build the Hypertransport interrupt support
obj-$(CONFIG_HT_IRQ) += htirq.o

obj-$(CONFIG_PCI_ATS) += ats.o
obj-$(CONFIG_PCI_IOV) += iov.o

#
# Some architectures use the generic PCI setup functions
#
obj-$(CONFIG_X86) += setup-bus.o
obj-$(CONFIG_ALPHA) += setup-bus.o setup-irq.o
obj-$(CONFIG_ARM) += setup-bus.o setup-irq.o
obj-$(CONFIG_UNICORE32) += setup-bus.o setup-irq.o
obj-$(CONFIG_PARISC) += setup-bus.o
obj-$(CONFIG_SUPERH) += setup-bus.o setup-irq.o
obj-$(CONFIG_PPC) += setup-bus.o
obj-$(CONFIG_FRV) += setup-bus.o
obj-$(CONFIG_MIPS) += setup-bus.o setup-irq.o
obj-$(CONFIG_X86_VISWS) += setup-irq.o
obj-$(CONFIG_MN10300) += setup-bus.o
obj-$(CONFIG_MICROBLAZE) += setup-bus.o
obj-$(CONFIG_TILE) += setup-bus.o setup-irq.o
obj-$(CONFIG_SPARC_LEON) += setup-bus.o setup-irq.o
obj-$(CONFIG_M68K) += setup-bus.o setup-irq.o

#
# ACPI Related PCI FW Functions
# ACPI _DSM provided firmware instance and string name
#
obj-$(CONFIG_ACPI)    += pci-acpi.o

# SMBIOS provided firmware instance and labels
obj-$(CONFIG_PCI_LABEL) += pci-label.o

obj-$(CONFIG_PCI_SYSCALL) += syscall.o

obj-$(CONFIG_PCI_STUB) += pci-stub.o

obj-$(CONFIG_XEN_PCIDEV_FRONTEND) += xen-pcifront.o

obj-$(CONFIG_OF) += of.o

ccflags-$(CONFIG_PCI_DEBUG) := -DDEBUG

# PCI host controller drivers
obj-y += host/
