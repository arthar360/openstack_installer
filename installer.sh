#!/bin/bash
cancel () {
if [ "$?" -ne "0" ]
then
dialog --msgbox "Operation Cancelled" 8 25
exit
fi
}

dialog --title "Openstack Installer" --msgbox "Welcome to OpenStack installer" 20 100


if [ $(free -m | grep Mem | awk '{print $2}') -lt "16000" ]
then
dialog --title "Openstack Installer" --yesno "Insufficient Memory. Recommended RAM size is > 16 GB. This can cause problems during installation. Do you want to continue?" 20 100
cancel
fi

dialog --title "Openstack Installer" --yesno "The following changes will be made\n \
	- EPEL repository will be enabled in this machine. \n \
	- NetworkManager will be removed \n \n \
	Is is ok?" 20 100
cancel	

init_sys_ready () {
systemctl stop NetworkManager
systemctl mask NetworkManager
yum remove NetworkManager firewall* mysql* 

if [ $(sestatus | grep config | awk '{print $NF}') == "enforcing" ]
then
dialog --title "Openstack Installer" --msgbox "SELinux is in enforcing mode." 20 100
fi
}
init_sys_ready 

OPENSTACK_VERSION=$(dialog  --title "Openstack Installer" --radiolist "Configure Options" 20 100 19 \
	ocata "(latest)" "" \
	newton "" "" \
	havana "" "" --output-fd 1)
cancel	


OPTIONS=$(dialog  --title "Openstack Installer" --form "Configure Options" 20 100 0 \
	"Default Password" 	1 3 "$controller" 	1 20 90 0 \
	"MariaDB Password" 	2 3 "$controller" 	2 20 90 0 \
	"Controller Host" 	3 3 "$controller" 	3 20 90 0 \
	"Compute Nodes" 	4 3 "$compute_nodes" 	4 20 90 0 \
	"Cert Directory" 	5 3 "~/packstackca" 	5 20 90 0 \
	"NTP Servers" 		6 3 "pool.ntp.org" 	6 20 90 0 \
	--output-fd 1)
cancel	


ADDITIONAL_OPTIONS=$(dialog  --title "Openstack Installer" --checklist "Configure Options" 20 100 19 \
	USE_EPEL "" "" \
	CONFIG_NAGIOS_INSTALL "" "" \
	CONFIG_HORIZON_SSL "" "" \
	CONFIG_HEAT_CLOUDWATCH_INSTALL "" "" \
	CONFIG_NEUTRON "" "" \
	HEAT_INSTALL "" "" \
	PROVISION_DEMO "" "" \
	--output-fd 1)
cancel	

mkdir ~/certs
cd
openssl req -x509 -sha256 -newkey rsa:2048 -keyout selfkey.key -out selfcert.crt -days 1024 -nodes 

cp -ip selfcert.crt /etc/pki/tls/certs/; cp -ip selfkey.key /etc/pki/tls/private/

mkdir -p ~/packstackca/certs

ln -s /etc/pki/tls/certs/ssl_vnc.crt /root/packstackca/certs/10.210.8.226ssl_vnc.crt
echo $OPTIONS $ADDITIONAL_OPTIONS
#cat /etc/sysconfig/selinux | grep -i "^SELINUX=" | awk -F "=" {print }
