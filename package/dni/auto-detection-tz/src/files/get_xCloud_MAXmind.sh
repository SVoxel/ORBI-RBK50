#! /bin/sh
# use for downloading /tmp/xCloud_MAXmind

claim_code=$(d2 xagentcfg[0].x_agent_claim_code|awk -F " " '{print $2}')
id=$(d2 xagentcfg[0].x_agent_id|awk -F " " '{print $2}')
dev_url="https://devicelocation.dev.ngxcld.com"
qa_url="https://devicelocation.qa.ngxcld.com"
prod_url="https://devicelocation.ngxcld.com"
remote_path="device-location/resolve"

load_tz_info(){
if [ "$1" = "" -o "$2" = "" ];then
	echo "[load tz info] ERROR: need 3 argu (server path,id,claim code)"
else
	case $1 in
		*"QA"*) full_path=$qa_url/$remote_path ;;
		*"DEV"*) full_path=$dev_url/$remote_path ;;
		*) full_path=$prod_url/$remote_path ;;
	esac
	curl -k -X GET $full_path -H "content-type: application/json" -H "Authorization:$1:$2" -o /tmp/xCloud_MAXmind --connect-timeout 3
fi
}

load_tz_info $id $claim_code

