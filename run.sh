#!/bin/bash

source ./answerfile.txt
source $(pwd)/bin/install.sh
source $(pwd)/bin/common.sh
source $(pwd)/bin/generate_ip_pass_table.sh
source $(pwd)/bin/mariadb.sh
#cat ./ip_pass_table.txt
#while true
#do 
#	echo "Is the IP:PASS table OK?(y/n)"
#	read input
#	if [[ $input = "y" ]] ;then
#		echo "Let's go!"
#		break
#	elif [[ $input = "n" ]] ;then
#		echo "Please Modify the ip_pass_table.txt manually!"
#		exit 1
#	fi
#	echo "Please type in "y" or "n"."
#	
#done

###### create hosts
generate_hosts

###### generate ip_pass_table.txt
#generate_ip_pass_table

######configure repos
#config_repos

###### generate ssh key, and distribute it to other nodes
#batch_sshkey

###### distribute hosts and repos
#distribute_hosts_repos

###### modify hostname for all nodes
#modify_hostname

###### configure timezone and ntp
#timedate_sync

###### disable SELinux and firewalld
#selinux_firewalld_disable

###### MariaDb Galera Cluster install
#mariadb_install  has not complete

###### RabbitMQ Cluster

#nova_install controller
#nova_install compute

#echo "$YUM_SERVER_IP"