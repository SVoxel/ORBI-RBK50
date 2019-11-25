#! /bin/bash

# Version 1.3
# Usage:	check_language.sh [<www_patch>]
# e.g.:
#	./check_language.sh ~/git_home/net-cgi.git/www
#	./check_language.sh

# regular expression type in this file:
#	grep		(BRE)
#	grep -E		(ERE)
#	sed		(BRE)
#	sed -r		(ERE)
#	find		(BRE)
#	expr		(BRE)

DIRS="browser_hijack,browser_hijack_3g,browser_hijack_lte,centria_cd_less"
IGNORE="ip_addr,pppoe_mark_ip,used_persent"

WWW="${1:-$(pwd)/../www}"
LANGUAGE_DIR="$WWW/language"
RESULT_DIR="./result"

SUCCESS=0
FAIL=1

#check valid lines: variable=value, comment line and blank line
check_equal() {
	# regular expression (ERE):
	#	^\w*\s*=\s*".*"\s*(//.*)?$	# variable and value
	#	^\s*(//.*)?$			# comment line or blank line
	#	^\xef\xbb\xbf			# UTF-8 BOM, really need this one???
	local check="$(grep -E -rnv '^\w*\s*=\s*".*"\s*(//.*)?$|^\s*(//.*)?$' $LANGUAGE_DIR)"
	if [ -n "${check}" ]; then
		echo "$check" >> "$RESULT_DIR/syntax.txt"
		printf "$FAIL"
	else
		printf "$SUCCESS"
	fi
}

#check double quote marks: fail if find '"..."..."', but exclude '"...\"..."'.
check_quote() {
	# regular expression (ERE):
	#	".*?(\\\\"|[^\]").*?"		# string value, include no-escape "
	local check="$(grep -E -rn '".*?(\\\\"|[^\]").*?"' $LANGUAGE_DIR)"
	if [ -n "${check}" ]; then
		echo "$check" >> "$RESULT_DIR/syntax.txt"
		printf "$FAIL"
	else
		printf "$SUCCESS"
	fi
}

#check javascript variables: fail if special js variable do not defined.
check_variable() {
	# search lines match regular expression $id, where may use js variables (in $LANGUAGE_DIR)
	id='document\.(write|createTextNode)'
	# group '...' part in "${id}(...)" to find javascript variables
	re='\(("[^+]+"\s*\+\s*)?(\w+)(\s*\+\s*"[^"]*?")?((\s*\+\s*)(\w+))?(\s*\+\s*"[^+]+")?\)'
	local dirs=$(eval echo ${WWW}/{${DIRS}})
	local vars="$(find $dirs -regex '.*\.htm[l]?$\|.*\.js$' 2>/dev/null | \
		xargs grep -Eroh "${id}${re}" | \
		sed -rn 's/'${id}${re}'/\3\n\7/gp' | \
		sed -r '/^$/d' | sort | uniq)"

	local ret=0
	local flag
	for var in $vars ; do
		grep -qr "^\<$var\>" "$LANGUAGE_DIR"
		if [ $? -ne 0 ]; then
			[ -n "$IGNORE" ] && \
				{ expr "$IGNORE" : "\<$var\>\|.*\<$var\>" > /dev/null && continue; }

			echo "$var" >> "$RESULT_DIR/invalid.txt"
			ret=1; continue
		fi

		flag=3
		grep -qr "^\<$var\>" "$LANGUAGE_DIR/English.js" && flag=1
		grep -qr "^\<$var\>" "$LANGUAGE_DIR/RU_flow_en.js" && flag=2

		if [ $flag -eq 3 ]; then
			echo "$var" >> "$RESULT_DIR/invalid_English.js"
			ret=1
		else
			for file in $(ls "$LANGUAGE_DIR" | grep -Ev 'English\.js|RU_flow_en\.js'); do
				grep -qr "^\<$var\>" "$LANGUAGE_DIR/$file"
				if [ $? -eq 1 ] ; then
					[ $flag -eq 1 -a "$file" != "RU_flow.js" ] \
						&& echo "$var" >> "$RESULT_DIR/invalid_$file" && ret=1
					[ $flag -eq 2 -a "$file" == "RU_flow.js" ] \
						&& echo "$var" >> "$RESULT_DIR/invalid_$file" && ret=1
				fi
			done
		fi
	done

	[ $ret -eq 0 ] && printf "$SUCCESS" || printf "$FAIL"
}

[ -d $RESULT_DIR ] && rm -rf $RESULT_DIR/* || mkdir -p $RESULT_DIR
[ $(($(check_equal) + $(check_quote) + $(check_variable))) -eq 0 ] \
	&& printf "success" || printf "fail"
