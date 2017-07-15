#!/bin/bash

generate_ip_pass_table () {
	UNIPASS=devops
	flag=0
# check if exist ip_pass_table.txt file, if ture delete
	if [ -e $(pwd)/ip_pass_table.txt ];then
		rm -rf $(pwd)/ip_pass_table.txt
	fi
	echo >$(pwd)/ip_pass_table.txt
#generate ip:pass talbe for all nodes
	for node in controller compute cinder nfs-bakend ;do
		for row in `cat /etc/hosts | grep $node | awk '{print $1}'`; do
			((flag=$flag + 1))
			if [[ $flag = 1 ]];then
				echo "$row:$UNIPASS" >ip_pass_table.txt
				sed -i '/^$/d' ip_pass_table.txt
			elif [[ $flag > 1 ]] ;then
				echo "$row:$UNIPASS" >>ip_pass_table.txt
			fi
		done
	done
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
scp_repos (){
flag=0
for i in `cat /etc/hosts | grep controller | awk '{print $1}'` ;do
	if [[ $flag >0 ]];then
		ssh root@$i mkdir /etc/yum.repos.d/bak
		ssh root@$i mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/
		for repo in `ls -l /etc/yum.repos.d/ | grep repo | awk '{print $9}'`; do
			scp /etc/yum.repos.d/$repo root@$i:/etc/yum.repos.d/
		done
	fi
	((flag=$flag + 1))
done
}
