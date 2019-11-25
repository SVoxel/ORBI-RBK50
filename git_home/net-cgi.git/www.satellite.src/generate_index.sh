#! /bin/bash

js_list="funcs.js \
	 js/connectDevices.js \
	 js/init.js \
	 js/jquery.min.js \
	 js/lang.js \
	 js/login.js \
	 js/setup.js \
	 js/upgrade.js"

css_list="css/advanced.css \
	  css/form.css \
	  css/hijack_style.css \
	  css/main.css \
	  css/normalize.min.css"

compress_file(){
	list=$1

	echo "Compress $result start ...";
	hasJava=$(which java)
	if [ "x$hasJava" != "x" ]; then
		for i in $list; do
			java -jar ../files/yuicompressor-2.4.8.jar -o $i --charset utf-8 $i;
		done;
	fi
	echo "Compress $result finished.";
}

compress_file "$js_list"
compress_file "$css_list"
