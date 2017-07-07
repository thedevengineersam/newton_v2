#!/bin/bash

hatch_hosts () {
	length=${#CONTROLLER_NODE[*]}
	ref=`expr $length - 1`
	if [[ $length > 0 ]] ;then
		for HOST in ${CONTROLLER_NODE[*]}; do
			node="controller"
			populate_hosts #controller_hosts			
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
			node="storage"
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
#	cp $(pwd)/etc/hosts /etc/hosts	
}

populate_hosts () {
# Only at the first time step in this function cp hosts from lib/hosts to etc/hosts and append comments of nodes
	if [[ $ref = `expr $length - 1` ]] && [[ $node = "controller" ]] ;then
		cp $(pwd)/lib/hosts $(pwd)/etc/hosts
		echo "# $node nodes" >> $(pwd)/etc/hosts
	elif [[ $ref = `expr $length - 1` ]] && ( [[ $node = "compute" ]] || [[ $node = "network" ]] || [[ $node = "storage" ]] );then
		echo "# $node nodes" >> $(pwd)/etc/hosts
	fi
# Compute the sequence of controller
	seq=`expr $length - $ref`
# Populate etc/hosts for controller nodes
	if [[ $length = 1 ]] ;then
		echo "$HOST	$node" >> $(pwd)/etc/hosts
	elif [[ $length > 1 ]] ;then
		echo "$HOST	$node-$seq" >> $(pwd)/etc/hosts
		if [[ $ref > 0 ]] ;then
			ref=`expr $ref - 1`
		fi
	fi	
	#if [[ $node ]]
}

config_repos () {
	echo "config repos..."
	cp $(pwd)/lib/repos/*.repo $(pwd)/repos/
	ls $(pwd)/repos/ | grep .repo > list.txt
	for i in `cat list.txt`;do
#		echo "$i"
		sed -i "s/yum_server_ip/${YUM_SERVER_IP[0]}/g" $(pwd)/repos/$i
	done
	mkdir /etc/yum.repos.d/bak-`date +%F-%H-%M-%S`
	mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak-`date +%F-%H-%M-%S`
	cp $(pwd)/repos/*.repo /etc/yum.repos.d/
	
#	yum clean all
#	yum makecache

}

batch_sshkey () {
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
				"
			fi 
			expect -c "
				spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$ip
				expect {
					\"*password:\" {send \"$password\r\";exp_continue}
					\"*password:\" {send \"$password\r\";}
				}
				"

		done
	}