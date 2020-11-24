#!/bin/sh

CONFIG="/bin/nvram"
SAMBA_DISABLED=$($CONFIG get samba_disable)

# Check the disk name
DISK=0
I=0
for I in a b c d e f g h i j k l m n o; do
	if [[ -d /mnt/sd"$I"1 ]]; then
		DISK=/mnt/sd"$I"1
		break
	fi
done

# No disk: exit
if [ $DISK = "0" ]; then
	/etc/init.d/avahi-daemon stop
	/etc/init.d/dbus stop
	exit 0
fi

# Set device biosname
if [ "x$($CONFIG get netbiosname)" = "x" ]; then
	NETBIOSNAME="$($CONFIG get Device_name)"
else
	NETBIOSNAME="$($CONFIG get netbiosname)"
fi

# Kill all samba daemons
/usr/bin/killall smbd > /dev/null 2>&1
/usr/bin/killall nmbd > /dev/null 2>&1

# Check custom config
if [ -f $DISK/overlay/etc/config/samba/smb.conf ]; then
	# Copy custom samba config to config dir
	cat $DISK/overlay/etc/config/samba/smb.conf > /etc/samba/smb.conf
else
	# Create default samba config
	echo "[global]" > /etc/samba/smb.conf
	echo "  workgroup = Workgroup" >> /etc/samba/smb.conf
	echo "  netbios name = $NETBIOSNAME" >> /etc/samba/smb.conf
	echo "  bind interfaces only = yes" >> /etc/samba/smb.conf
	echo "  server string = NETGEAR Orbi RBK50" >> /etc/samba/smb.conf
	echo "  unix charset = UTF8" >> /etc/samba/smb.conf
	echo "  display charset = UTF8" >> /etc/samba/smb.conf
	echo "  log file = /var/log.samba" >> /etc/samba/smb.conf
	echo "  log level = 0" >> /etc/samba/smb.conf
	echo "  max log size = 5" >> /etc/samba/smb.conf
	echo "  obey pam restrictions = no" >> /etc/samba/smb.conf
	echo "  disable spoolss = yes" >> /etc/samba/smb.conf
	echo "  strict allocate = no" >> /etc/samba/smb.conf
	echo "  host msdfs = no" >> /etc/samba/smb.conf
	echo "  security = user" >> /etc/samba/smb.conf
	echo "  map to guest = Bad User" >> /etc/samba/smb.conf
	echo "  encrypt passwords = yes" >> /etc/samba/smb.conf
	echo "  pam password change = no" >> /etc/samba/smb.conf
	echo "  null passwords = yes" >> /etc/samba/smb.conf
	echo "  smb encrypt = disabled" >> /etc/samba/smb.conf
	echo "  max protocol = SMB2" >> /etc/samba/smb.conf
	echo "  passdb backend = smbpasswd" >> /etc/samba/smb.conf
	echo "  smb passwd file = /etc/samba/smbpasswd" >> /etc/samba/smb.conf
	echo "  enable core files = no" >> /etc/samba/smb.conf
	echo "  deadtime = 30" >> /etc/samba/smb.conf
	echo "  force directory mode = 0777" >> /etc/samba/smb.conf
	echo "  force create mode = 0777" >> /etc/samba/smb.conf
	echo "  use sendfile = yes" >> /etc/samba/smb.conf
	echo "  map archive = no" >> /etc/samba/smb.conf
	echo "  map hidden = no" >> /etc/samba/smb.conf
	echo "  map read only = no" >> /etc/samba/smb.conf
	echo "  map system = no" >> /etc/samba/smb.conf
	echo "  store dos attributes = no" >> /etc/samba/smb.conf
	echo "  dos filemode = yes" >> /etc/samba/smb.conf
	echo "  oplocks = yes" >> /etc/samba/smb.conf
	echo "  level2 oplocks = yes" >> /etc/samba/smb.conf
	echo "  kernel oplocks = no" >> /etc/samba/smb.conf
	echo "  wide links = no" >> /etc/samba/smb.conf
	echo "  min receivefile size = 16384" >> /etc/samba/smb.conf
	echo "  socket options = IPTOS_LOWDELAY TCP_NODELAY SO_KEEPALIVE SO_RCVBUF=131072 SO_SNDBUF=131072" >> /etc/samba/smb.conf

	echo "[USB]" >> /etc/samba/smb.conf
	echo "  path=$DISK" >> /etc/samba/smb.conf
	echo "  browsable=yes" >> /etc/samba/smb.conf
	echo "  guest ok=yes" >> /etc/samba/smb.conf
	echo "  read only=no" >> /etc/samba/smb.conf
fi

# Exit if samba disabled
if [ "$SAMBA_DISABLED" = "1" ]; then
	exit 0
fi

# Start samba if not disabled
/usr/sbin/taskset -c 1 /usr/sbin/smbd -D > /dev/null 2>&1
/usr/sbin/taskset -p 1 `/bin/pidof usb-storage` > /dev/null 2>&1
/usr/sbin/nmbd -D
