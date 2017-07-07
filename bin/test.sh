systemctl status firewalld 1>/dev/null 2>&1
if [[ $? = 0 ]] ;then
systemctl stop firewalld
yum remove firewalld -y 1>/dev/null 
elif [[ $? = 3 ]] ;then
yum remove firewalld -y 1>/dev/null 
fi