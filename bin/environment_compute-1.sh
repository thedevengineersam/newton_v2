#!/bin/bash

NTPSERVER="192.168.6.3"	# attention: NTPSERVER IP
HOSTNAME="compute-1"
IP_SEGMENT="192.168.6.0\/24"
SCRIPTS_PATH="~/scripts-newton"
ENV_SCRIPT="environment_compute-1.sh"  
###### modify hostname
modify_hostname () {
if [[ $(hostname) != $HOSTNAME ]] ;then
	hostnamectl set-hostname $HOSTNAME
fi
}
#######disable_sellinux_firewall
disable_sellinux_firewall () {
echo "Stop & Disable firewalld..."
systemctl status firewalld 1>/dev/null 2>&1
flag=$?
if [[ $flag = 0 ]] ;then
systemctl stop firewalld
systemctl disable firewalld
#systemctl erase firewalld
elif [[ $flag = 3 ]] ;then
systemctl disable firewalld
#systemctl erase firewalld
fi
echo "disable SELinux..."
SE=`sestatus | awk '{print $3}'`
if [[ $SE = disabled ]] ;then
	SE=0
	echo "$SE"
elif [[ $SE = enforcing ]] ;then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi
echo "bash $SCRIPTS_PATH/$ENV_SCRIPT" >> ~/.bash_profile 	# attention:directory scripts-newton
reboot
}
######Check firewalld SELinux
check_firewall_selinux () {
sed -i "s/bash $SCRIPTS_PATH\/$ENV_SCRIPT//g" ~/.bash_profile
echo "Check firewalld status:"
FW=`systemctl status firewalld | grep Active | awk '{print $2}'`
EN=`systemctl status firewalld  | grep Loaded | cut -d ';' -f 2 | cut -d ' ' -f 2`
if [[ $FW = inactive ]] && [[ $EN=disabled ]];then
	FW=0
elif [[ $FW = active ]] ;then 
	systemctl stop firewalld 1>/dev/null
	FW=10
else 
	systemctl disable firewalld 1>/dev/null
	FW=20
fi
echo "$FW"
echo "Check SELinux status:"
SE=`sestatus | awk '{print $3}'`
if [[ $SE = disabled ]] ;then
	SE=0
fi
echo "$SE"
}
######config NTP(chrony)
config_chrony_server () {
timedatectl set-timezone Asia/Shanghai
yum install chrony -y 1>/dev/null 2&>1 
sed -i '/^server 0.centos.pool.ntp.org iburst/,/^server 3.centos.pool.ntp.org iburst/s/^/#/g' /etc/chrony.conf 
sed -i "/^#server 3.centos.pool.ntp.org iburst/a\server $NTPSERVER iburst" /etc/chrony.conf  	#attention: $NTPSERVER use ""
#sed -i "s/#allow 192.168\/16/allow $IP_SEGMENT/g"  /etc/chrony.conf		# attention: network segement
sed -i 's/#local stratum 10/local stratum 10/g'  /etc/chrony.conf
systemctl restart chronyd 
systemctl enable chronyd
chronyc sources 1> /dev/null 2&>1
sleep 1s
chronyc sources
}
###### Configure DNS(/etc/hosts)
test_hosts() {
	#attention: IP <--> hostname
echo "Test hosts ..."
echo "Ping controller..."
ping -c 4 controller 1>/dev/null
echo "Ping compute-1..."
ping -c 4 compute-1	1>/dev/null
echo "Ping compute-2..."
ping -c 4 compute-2 1>/dev/null
echo "Ping compute-3..."
ping -c 4 compute-3 1>/dev/null
echo "Ping network..."
ping -c 4 network   1>/dev/null
echo "Ping storage-1..."
ping -c 4 storage-1 1>/dev/null
echo "Ping storage-2..."
ping -c 4 storage-2 1>/dev/null
#ping -c 4 www.baidu.com
}

echo "Select a operation:"
select opt in modify_hostname disable_sellinux_firewall check_firewall_selinux config_chrony_server test_hosts  "Exit"
do 
	case $opt in
	modify_hostname)
		modify_hostname ;;
	disable_sellinux_firewall)
		disable_sellinux_firewall;;
	check_firewall_selinux)
		check_firewall_selinux ;;
	config_chrony_server)
		config_chrony_server ;; 
	test_hosts)
		test_hosts ;;

	"Exit")
		break 0;;
	*)
		echo "Please select a number between 1 and 10 !"
		continue;;
	esac
done
