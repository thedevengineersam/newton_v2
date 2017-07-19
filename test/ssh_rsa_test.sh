for row in $(cat ip_pass_table.txt)
	do
		ip=$(echo "$row" | cut -f1 -d ":")
		password=$(echo "$row" | cut -f2 -d ":")
		expect -c "
			spawn ssh root@$ip
			expect {
				\"from\" {send \"exit\r\"}
				}
		"
		echo $?
	done

