
include $(NETCGI_CONF)

# opt_folders is a string list of all selected folders' name in www
opt_folders:=


define copy_folder
	$(CP) $(1)/* $(WWW_OUT_DIR_CC);
endef

virtual_cgis:=apply.cgi func.cgi upgrade_check.cgi upgrade.cgi \
	backup.cgi brs_backup.cgi restore.cgi langupg.cgi \
	ubootupg.cgi unauth.cgi recover.cgi debug_cloud.cgi \
	debug.cgi green_upg.cgi bt_file.cgi mobile_install.cgi \
	admin.cgi

.PHONY: all install clean
all:
	echo $(opt_folders)
	./generate_index.sh
	$(INSTALL_DIR)		$(WWW_OUT_DIR_CC)
	$(CP) *.*		$(WWW_OUT_DIR_CC)
	$(CP) image/		$(WWW_OUT_DIR_CC)
	$(CP) css/		$(WWW_OUT_DIR_CC)
	$(CP) js/		$(WWW_OUT_DIR_CC)
#	$(CP) language/		$(WWW_OUT_DIR_CC)
#ifeq ($(NEW_SOURCE),)
#	$(CP) cgi-bin/		$(WWW_OUT_DIR_CC)
#endif

	$(foreach n,$(strip $(opt_folders)),$(call copy_folder,$(n)))

	$(TOUCH) $(foreach n,$(virtual_cgis),$(WWW_OUT_DIR_CC)/$(n))

install:
	$(INSTALL_DIR)			$(INS_WWW_DIR_CC)
	$(CP) $(WWW_SRC_DIR_CC)/*	$(INS_WWW_DIR_CC)

clean:
	rm -rf $(WWW_OUT_DIR_CC)
