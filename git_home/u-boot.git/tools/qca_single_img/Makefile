#
# Fetch single image tool from $(GIT_HOME)/qsdk-chipcode.git and pack U-Boot
# into single image.
#
# Please pass following variables to this Makefile:
#    "CONFIG_QCA_SINGLE_IMG_GIT": /path/to/qsdk-chipcode.git
#    "CONFIG_QCA_SINGLE_IMG_TREEISH": git commit of qsdk-chipcode.git to be
#                                     fetched.


#
# load "src" and "obj" from config.mk of U-Boot
#
# "src" and "obj" are only used in remote build function of U-Boot.
#
ifneq "$(TOPDIR)" ""
include $(TOPDIR)/config.mk
endif

sinclude $(obj)config.mk


# Default value for required variables
GIT_HOME ?= $(HOME)/git-home
CONFIG_QCA_SINGLE_IMG_GIT ?= $(GIT_HOME)/qsdk-chipcode.git

prepared = $(addprefix qsdk-chipcode/,.prepared_$(CONFIG_QCA_SINGLE_IMG_TREEISH))


all: $(obj)$(prepared)

prepare: $(obj)$(prepared)

.PHONY: all prepare

$(obj)$(prepared):
	@echo -e "\n###### Preparing QCA single image tool ######"
	@echo -e "\n###### Fetching QCA single image tool"
	rm -rf $(obj)qsdk-chipcode/

	if [ -z "$(CONFIG_QCA_SINGLE_IMG_TREEISH)" ]; then \
		echo -e "\nERROR: Please specify commit of qsdk-chipcode.git in make variable \"CONFIG_QCA_SINGLE_IMG_TREEISH\""; \
		exit 1; \
	fi
	git archive --format=tar --prefix=qsdk-chipcode/ --remote=$(CONFIG_QCA_SINGLE_IMG_GIT)/ $(CONFIG_QCA_SINGLE_IMG_TREEISH) | tar -C $(obj)./ -xf -

	@echo -e "\n###### Replacing files with local ones"
	if [ -d "files" ]; then \
		cp -a files/./ $(obj)qsdk-chipcode/; \
	fi

	@echo -e "\n###### Applying local patches"
	if [ -d "patches" ] && [ "$$(ls patches | wc -l)" -gt 0 ]; then \
		./patch-kernel.sh qsdk-chipcode patches; \
	fi

	@> $@
	@echo -e "\n###### QCA single image tool is prepared [$(notdir $@)]. ######\n"

patch_clean:
	rm -f $(obj)$(prepared)
	rm -fr $(obj)files/ $(obj)patches/

clean: patch_clean
	rm -fr $(obj)qsdk-chipcode/

.PHONY: clean patch_clean
