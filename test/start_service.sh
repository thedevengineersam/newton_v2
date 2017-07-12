#!/bin/bash

SERVICE=$1
echo "Check $SERVICE status..."
systemctl status  $SERVICE 1>/dev/null 2>&1
flag=$?
if [[ $flag = 0 ]] ;then
	echo "$SERVICE is running."
elif [[ $flag = 3 ]] ;then
	echo "$SERVICE is starting from dead"
	systemctl start $SERVICE 1>/dev/null
	systemctl enable $SERVICE 1>/dev/null
	echo "Done."
fi
