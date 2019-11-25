
function check_orange()
{
	var cf = document.forms[0];
	if(cf.Orange_type.value=="")
	{
		alert("Please select your ISP profile");
		return false;
	}

	if(cf.orange_login.value=="")
	{
		alert("Login name cannot be blank.");
		return false;
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
	cf.submit();
}

