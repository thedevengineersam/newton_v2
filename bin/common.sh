#!/bin/bash

# generate hosts
function generate_hosts () {
#for tuple in CONTROLLER_NODE[*] COMPUTE_NODE[*] NETWORK_NODE[*] STORAGE_NODE[*] NFS_BACKEND[*] ;do
#	TUPLE=$tuple
#	length=${#TUPLE}
#	ref=`expr $length - 1`
#	if [[ $length > 0 ]] ;then
#		for HOST in $TUPLE; do
#			if [[ "$tuple" = "CONTROLLER_NODE[*]" ]] ;then
#				node="controller"
#			elif [[ "$tuple" = "COMPUTE_NODE[*]" ]] ;then
#				node="compute"
#			elif [[ "$tuple" = "NETWORK_NODE[*]" ]] ;then
#				node="network"
#			elif [[ "$tuple" = "STORAGE_NODE[*]" ]] ;then
#				node="cinder"
#			elif [[ "$tuple" = "NFS_BACKEND[*]" ]] ;then
#				node="nfs_backend"		
#			fi
#			echo $node
#			echo $HOST
#			echo $length
#			#populate_hosts #controller_hosts			
#		done 
#	fi
#done
#}
echo "Populate hosts..."
length=${#CONTROLLER_NODE[*]}
ref=`expr $length - 1`
if [[ $length > 0 ]] ;then
	for HOST in ${CONTROLLER_NODE[*]}; do
		node="controller"
		populate_hosts #compute_hosts			
	done
fi

length=${#COMPUTE_NODE[*]}
ref=`expr $length - 1`
if [[ $length > 0 ]] ;then
	for HOST in ${COMPUTE_NODE[*]}; do
		node="compute"
		populate_hosts #compute_hosts			
	done
fi	

length=${#NETWORK_NODE[*]}
ref=`expr $length - 1`
if [[ $length > 0 ]] ;then
	for HOST in ${NETWORK_NODE[*]}; do
		node="network"
		populate_hosts #network_hosts
	done
fi	

length=${#STORAGE_NODE[*]}
ref=`expr $length - 1`
if [[ $length > 0 ]] ;then
	for HOST in ${STORAGE_NODE[*]}; do
		node="cinder"
		populate_hosts #storage_hosts
	done
fi

length=${#NFS_BACKEND[*]}
ref=`expr $length - 1`
if [[ $length > 0 ]] ;then
	for HOST in ${NFS_BACKEND[*]}; do
		node="nfs_backend"
		populate_hosts #storage_hosts
	done
fi
	
length=1
ref=`expr $length - 1`
if [[ $length > 0 ]] ;then
	for HOST in ${VIP[0]}; do
		node="www.qiming.com"
		populate_hosts #storage_hosts
	done
fi

#	length=${#YUM_SERVER_IP[*]}
#	ref=`expr $length - 1`
#	if [[ $length > 0 ]] ;then
#		for HOST in ${YUM_SERVER_IP[*]};do
#			node=yum_server_ip
#			populate_hosts
#		done
#	fi
# for test##############
echo "Copy hosts file to /etc/hosts..."
cp $(pwd)/etc/hosts /etc/hosts	
echo "Done."
}

###### Populate hosts for node
function populate_hosts () {
# Only at the first time step in this function cp hosts from lib/hosts to etc/hosts and append comments of nodes
if [[ $ref = `expr $length - 1` ]] && [[ $node = "controller" ]] ;then
	if [ -e $(pwd)/etc/hosts ] ;then
		rm -rf $(pwd)/etc/hosts
	fi
	cp $(pwd)/lib/hosts $(pwd)/etc/hosts
	echo "# $node nodes" >> $(pwd)/etc/hosts
elif [[ $ref = `expr $length - 1` ]] && ( [[ $node = "compute" ]] || [[ $node = "network" ]] || [[ $node = "cinder" ]] || [[ $node = "nfs_backend" ]]);then
	echo "# $node nodes" >> $(pwd)/etc/hosts
fi
# Compute the sequence of controller
seq=`expr $length - $ref`
# Populate etc/hosts for controller nodes
if [[ $length = 1 ]] ;then
	echo "$HOST	$node" >> $(pwd)/etc/hosts
elif [[ $length > 1 ]] ;then
	echo "$HOST	$node$seq" >> $(pwd)/etc/hosts
	if [[ $ref > 0 ]] ;then
		ref=`expr $ref - 1`
	fi
fi	
#if [[ $node ]]
}

###### Configure repos
function config_repos () {
echo "config repos..."
rm -f $(pwd)/repos/*
cp $(pwd)/lib/repos_v2/*.repo $(pwd)/repos/
#ls $(pwd)/repos/ | grep .repo > list.txt
#for i in `cat list.txt`;do
for i in `ls -l /etc/yum.repos.d/ | grep repo | awk '{print $9}'` ;do
#	echo "$i"
	sed -i "s/yum_server_ip/${YUM_SERVER_IP[0]}/g" $(pwd)/repos/$i
done
#echo "Done."
echo "copy repo files to /etc/yum.repos.d/..."
mkdir /etc/yum.repos.d/bak-`date +%F-%H-%M-%S`
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak-`date +%F-%H-%M-%S`
cp $(pwd)/repos/*.repo /etc/yum.repos.d/
#echo "Done."
echo "clean cache and make cache..."
yum clean all 1>/dev/null 2>&1
yum makecache 1>/dev/null 2>&1
if [[ $? = 0 ]];then
	echo "Done."
fi

}

###### Generation ssh rsa key and Batch distribute it to other node relying on ip_pass_table.txt
function batch_sshkey () {
echo "install expect..."
yum install expect -y 1>/dev/null
echo "generate keys..."
rm -rf /root/.ssh/id_rsa*
ssh-keygen -t rsa -P '' -f/root/.ssh/id_rsa 1>/dev/null
echo "distribure pub_key..."
for row in $(cat ip_pass_table.txt)
	do
		ip=$(echo "$row" | cut -f1 -d ":")
		password=$(echo "$row" | cut -f2 -d ":")
		known_host=`grep $ip /root/.ssh/known_hosts`
		if [ "$known_host" = "" ] ; then
			expect -c "
			spawn ssh root@$ip
			expect {
				\"*yes/no*\" {send \"yes\r\";exp_continue}
				\"*password:\" {send \"$password\r\";}
			}
			" 1>/dev/null
		fi 
		expect -c "
			spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$ip
			expect {
				\"*password:\" {send \"$password\r\";exp_continue}
				\"*password:\" {send \"$password\r\";}
			}
			" 1>/dev/null
	done
echo "Done."
}

###### distribute hosts repos to all nodes relying on ssh_rsa_pub_key
function distribute_hosts_repos () {
echo "Distribute hosts repos..."
flag=0
for node in controller compute network cinder nfs_backend ;do
	for ip in `cat /etc/hosts | grep -v "^#" | grep $node | awk '{print $1}'`; do
#		flag=0
		# jugement, controller1 won't copy just flag+1
		if [[ $node = "controller" ]] && [[ $flag = 0 ]];then
			((flag=$flag + 1))
		else
		# copy hosts to remote node
			scp /etc/hosts root@$ip:/etc/hosts
			is_empty=`ssh root@$ip ls /etc/yum.repos.d/ | grep repo`
			if [[ $is_empty != "" ]] ; then
				ssh root@$ip mkdir /etc/yum.repos.d/bak-`date +%F-%H-%M`
				for repo in $is_empty ;do
					ssh root@$ip mv /etc/yum.repos.d/$repo /etc/yum.repos.d/bak-`date +%F-%H-%M`/
				done
			fi
			scp /etc/yum.repos.d/*.repo root@$ip:/etc/yum.repos.d/
		fi
	done
done
echo "Done"
}

# modify all nodes's hostname relying on /etc/hosts and ssh_rsa_pub_key
function modify_hostname () {
for node in controller compute network cinder nfs_backend ;do
	for ip in `cat $(pwd)/etc/hosts | grep -v '^#' | grep $node | awk '{print $1}'`; do
#		ssh root@$ip 'timedatectl set-timezone Asia/Shanghai'
		HOSTNAME=`cat $(pwd)/etc/hosts | grep $ip | awk '{print $2}'`
		ssh root@$ip "hostnamectl set-hostname $HOSTNAME"
	done
done	
}

###### timedate_sync relying on /etc/hosts and ssh_rsa_pub_key
function timedate_sync () {
flag=0
for node in controller compute network cinder nfs_backend ;do
	for ip in `cat $(pwd)/etc/hosts | grep -v '^#' | grep $node | awk '{print $1}'`; do
		ssh root@$ip 'timedatectl set-timezone Asia/Shanghai'
		if [[ $node = "controller" ]] && [[ $flag = 0 ]] ;then
			# judgment ntp is installed or not on controller1
			is_installed=`ntpq -p | grep INIT`
			if [[ $is_installed != "" ]] ;then
				echo "NTP has installed on node $ip."
			else
			# install ntp and configure ntp, then start ntp
				yum install -y ntp 1>/dev/null
				sed -i '/^server 0.centos.pool.ntp.org iburst/,/^server 3.centos.pool.ntp.org iburst/s/^/#/g' /etc/ntp.conf
				sed -i "/^#server 3.centos.pool.ntp.org iburst/ a\server $NTP_SERVER iburst" /etc/ntp.conf
				systemctl restart ntpd
				systemctl enable ntpd
			fi
		else
			# judgment ntp is installed or not on other nodes
			is_installed=`ssh root@$ip 'ntpq -p | grep INIT'`
			if [[ $is_installed != "" ]] ;then
				echo "NTP has installed on node $ip."
			else
				ssh root@$ip yum install -y ntp 1>/dev/null
#				ssh root@$ip "sed -i '/^serddver 0.centos.pool.ntp.org iburst/,/^server 3.centos.pool.ntp.org iburst/s/^/#/g' /etc/ntp.conf"
#				ssh root@$ip "sed -i "/^#server 3.centos.pool.ntp.org iburst/ a\server $NTP_SERVER iburst" /etc/ntp.conf"
				scp /etc/ntp.conf root@$ip:/etc/ntp.conf
				ssh root@$ip systemctl restart ntpd
				ssh root@$ip systemctl enable ntpd
			fi
		
		fi
	done
done
}

###### disable SELinux and firewalld
function selinux_firewalld_disable () {
flag=0
for node in controller compute network cinder nfs_backend ;do
	for ip in `cat $(pwd)/etc/hosts | grep -v '^#' | grep $node | awk '{print $1}'`; do
		# jugement, controller1 will directly be configued by command and flag+1
		if [[ $node = "controller" ]] && [[ $flag = 0 ]];then
			# disable firewalld
			systemctl status firewalld 1>/dev/null 2>&1
			tap=$?
			# firewalld running then stop and disable
			if [[ $tap = 0 ]] ;then
				systemctl stop firewalld
				systemctl disable firewalld
			# firewalld dead then disable
			elif [[ $tap = 3 ]] ;then
				systemctl disable firewalld
				#echo $flag
			fi
			# disable SELinux
			SE=`sestatus | awk '{print $3}'`
			if [[ $SE = disabled ]] ;then
				SE=0
				#echo $SE
			elif [[ $SE = enforcing ]] ;then
				sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
			fi
			((flag=$flag + 1))
		else
		# disable firewalld & SELinux of remote nodes
			#just overwrite other nodes's selinux/config 			
			scp /etc/selinux/config root@$ip:/etc/selinux/config
			ssh root@$ip setenforce 0
			ssh root@$ip "systemctl stop firewalld;systemctl disable firewalld"
		fi
	done
done
}