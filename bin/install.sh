#!/bin/bash

source ./answerfile.txt
function nova_controller_install () 
{
#	length=${#CONTROLLER_NODE[*]}
#	ref=`expr $length - 1`
	for HOST in ${CONTROLLER_NODE[*]}; do
#		node="controller"
		echo "In controller node $HOST install"
	done 
}

function nova_compute_install () 
{
	for HOST in ${COMPUTE_NODE[*]}; do
#		node="compute"
		echo "In compute node $HOST install"
	done 
}

function nova_install () 
{
	if [[ "$1" = "controller" ]] ;then
		nova_controller_install
	elif [[ "$1" = "compute" ]] ;then
		nova_compute_install
	else
		echo 'The TYPE of node is not surported.'
	fi
}
