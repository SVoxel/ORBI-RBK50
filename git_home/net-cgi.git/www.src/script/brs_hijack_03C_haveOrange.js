
function check_orange()
{
	var cf = document.forms[0];
	if(cf.Orange_type.value=="")
	{
		alert("Please select your ISP profile");
		return false;
	}

	if(cf.Orange_type.value != "singtel_singa_dhcp" && cf.Orange_type.value != "unifi_malaysia_dhcp" && cf.Orange_type.value != "maxis_malaysia_dhcp"){
		if(cf.orange_login.value=="")
		{
			alert(bh_login_name_null);
			return false;
		}
	}
	for(var i=0;i<cf.orange_login.value.length;i++)
	{
		if(isValidChar(cf.orange_login.value.charCodeAt(i))==false)
		{
			alert("Invalid login name,\ncan't accept non-English words!");
			return false;
		}
	}

	if(cf.enable_orange.checked == true)
	{
		cf.hidden_enable_orange.value = "1";
	} else {
		cf.hidden_enable_orange.value = "0";
	}
	top.orange_apply_flag="1";
	if(cf.enable_orange.checked == true){
	  if(cf.Orange_type.value == "singtel_singa_dhcp" || cf.Orange_type.value == "unifi_malaysia_dhcp" || cf.Orange_type.value == "maxis_malaysia_dhcp"){
		var wired=0;
		var wireless=0;
		for(var count=0; count<lan_ports_num; count++){
			if(eval("cf.iptv_ports_"+count+".checked==true"))
				wired += Math.pow(2, count);
		}
			if(wired==Math.pow(2, lan_ports_num)-1)
			{
				alert("$vlan_error6");
				return false;
			}
			if(wired==0)
			{
				alert("$vlan_error5");
				return false;
			}
        		
		cf.hid_wired_port.value=wired;
		//cf.hid_wireless_port.value=wireless;
	  }
	}

	cf.submit();
}

