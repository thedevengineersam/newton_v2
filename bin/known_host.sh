#!/usr/bin/expect -f 

set timeout 30 
spawn ssh root@$ip
expect "(yes/no)?"
send "yes\r"
expect "password:"
send "$password\r"
expect "from"
send "exit\r"
interact

