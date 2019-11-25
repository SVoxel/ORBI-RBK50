#!/bin/sh

INSTALL_DIR="/opt/bitdefender"
#Bitdefender suggest to back the whole etc folder
BD_Agent_Config="etc"
BD_BACKUP="/bd_backup_dir"

Upgrade_BD_with_Prebuid()
{
	opt=$1
	case $opt in
		"backup")
			#If config of last time is not applied success,do not backup
			[ -d "$INSTALL_DIR/$BD_BACKUP" ] && exit 0
			if [ -d "$INSTALL_DIR/$BD_Agent_Config" ]; then
				mkdir -p $BD_BACKUP
				cp -rf "$INSTALL_DIR/$BD_Agent_Config" $BD_BACKUP
				rm -rf "$INSTALL_DIR"/*
				mv $BD_BACKUP $INSTALL_DIR
			fi
			;;
		"restore")
			if [ -d "$INSTALL_DIR/$BD_BACKUP" ]; then
				cp -rf "$INSTALL_DIR/$BD_BACKUP/$BD_Agent_Config/storage.data" "$INSTALL_DIR/$BD_Agent_Config/"
				rm -rf "$INSTALL_DIR/$BD_BACKUP"
			fi
			;;
	esac
}

Upgrade_BD_with_Prebuid $1
