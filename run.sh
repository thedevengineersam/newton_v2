#!/bin/bash

source ./answerfile.txt
source $(pwd)/bin/install.sh
source $(pwd)/bin/common.sh

hatch_hosts
config_repos
batch_sshkey

nova_install controller
nova_install compute

#echo "$YUM_SERVER_IP"