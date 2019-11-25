#!/bin/sh

rm -rf $1/bin/module_scan_result.txt
touch $1/bin/module_scan_result.txt
result_file="$1/bin/module_scan_result.txt"
scan_file="$1/orbi_common_module_list"

while read LINE
do
	module_name=`echo $LINE|cut -d "#" -f 1`
	module_path=`echo $LINE|cut -d "#" -f 2`
	if [ "x$module_path" = "xNA" ] || [ "x$module_path" = "xNo use common module" ];then
		echo "$module_name=$module_path" >> $result_file
	else
		module_tag=`echo $LINE|cut -d "#" -f 3`
		module_TREEISH=`cat $1$module_path|grep $module_tag|cut -d "=" -f 2|sed 's/"//g'`
		echo "$module_name=$module_TREEISH" >> $result_file
	fi
done < $scan_file
