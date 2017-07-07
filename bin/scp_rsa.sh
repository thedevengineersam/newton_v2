#!/usr/bin/expect 


	for row in $(cat ip_pass_table.txt)
		do
			ip=$(echo "$row" | cut -f1 -d ":")
			password=$(echo "$row" | cut -f2 -d ":")
#			ssh-copy-id -o stricthostkeychecking=no $ip
			known_host=`grep $ip /root/.ssh/known_hosts`
			if [ "$known_host" = "" ] ; then
#				chmod u+x $(pwd)/bin/known_host.sh
#				expect $(pwd)/bin/known_host.sh
				expect -c "
				spawn ssh root@$ip
				expect {
					\"*yes/no*\" {send \"yes\r\";exp_continue}
					\"*password*\" {send \"$password\r\";}
				}
				"
			fi 
#			chmod u+x $(pwd)/bin/scp_rsa.sh
#			expect $(pwd)/bin/scp_rsa.sh
			expect -c "
				spawn ssh-copy-id root@$ip
				expect {
					\"*password*\" {send \"$password\r\";}
				}
				"

		done

#set timeout 30 
#spawn ssh-copy-id root@$ip
#expect "password:"
#send "$password\r"
#expect "from"
#send "exit\r"
#interact