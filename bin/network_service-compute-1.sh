#!/bin/bash

RABBIT_PASS="123"
NEUTRON_PASS="123"
PROVIDER_IN="eth1"  #PROVIDER_INTERFACE_NAME
OVERLAY_IP="192.168.6.7" #OVERLAY_INTERFACE_IP_ADDRESS
NEUTRON_PASS="123" #NEUTRON_PASS
#This is a mark to identify the network Option
#option_mark=0
######Install and configure the common components
install_common_components () {
yum install openstack-neutron-linuxbridge ebtables ipset openstack-utils -y 1>/dev/null
#Configure the common component
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
grep -v "^#" /etc/neutron/neutron.conf | grep -v "^$" > neutron.conf
openstack-config --set neutron.conf DEFAULT transport_url  rabbit://openstack:$RABBIT_PASS@controller 
openstack-config --set neutron.conf DEFAULT auth_strategy keystone 	#attention:RABBIT_PASS
openstack-config --set neutron.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set neutron.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set neutron.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set neutron.conf keystone_authtoken auth_type password
openstack-config --set neutron.conf keystone_authtoken project_domain_name default
openstack-config --set neutron.conf keystone_authtoken user_domain_name default
openstack-config --set neutron.conf keystone_authtoken project_name service
openstack-config --set neutron.conf keystone_authtoken username neutron
openstack-config --set neutron.conf keystone_authtoken password $NEUTRON_PASS  	#attention:NEUTRON_PASS
openstack-config --set neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
cp neutron.conf /etc/neutron/neutron.conf
rm -rf neutron.conf
echo "*******************************************************
Attention: Only select Provider or Self-Service networks! "
}
##############################################Configure networking options###############################
######Networking Option 1: Provider networks
option_provider_networks () {
#option_mark=1
#Configure the Linux bridge agent	
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
grep -v "^#" /etc/neutron/plugins/ml2/linuxbridge_agent.ini | grep -v "^$" > linuxbridge_agent.ini
sed -i '/\[linux_bridge\]/ a\physical_interface_mappings = provider:eth0' linuxbridge_agent.ini 	#attention:PROVIDER_INTERFACE_NAME
sed -i '/\[vxlan\]/ a\enable_vxlan = false' linuxbridge_agent.ini
sed -i '/\[securitygroup\]/ a\
enable_security_group = true \
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver' linuxbridge_agent.ini
cp linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
rm -rf linuxbridge_agent.ini 
}

######Networking Option 2: Self-service networks
option_self_serviece_networks () {
#Configure the Linux bridge agent
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
grep -v "^#" /etc/neutron/plugins/ml2/linuxbridge_agent.ini | grep -v "^$" > linuxbridge_agent.ini
openstack-config --set linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$PROVIDER_IN 	#attention:PROVIDER_INTERFACE_NAME
openstack-config --set linuxbridge_agent.ini vxlan enable_vxlan true
openstack-config --set linuxbridge_agent.ini vxlan local_ip $OVERLAY_IP 	#attention:OVERLAY_INTERFACE_IP_ADDRESS
openstack-config --set linuxbridge_agent.ini vxlan l2_population true	
openstack-config --set linuxbridge_agent.ini securitygroup enable_security_group true
openstack-config --set linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
cp linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
rm -rf linuxbridge_agent.ini
}
#######finalize_configure_networking
finalize_configure_networking () {
#Configure the Compute service to use the Networking service
openstack-config --set /etc/nova/nova.conf neutron url http://network:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password $NEUTRON_PASS 	#attention:NEUTRON_PASS
#Finalize installation
systemctl restart openstack-nova-compute.service
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service

#openstack extension list --network
#openstack network agent list
}

echo "Select an Operation:"
select opt in install_common_components option_provider_networks option_self_serviece_networks finalize_configure_networking exit
do
	case $opt in 
	install_common_components)
		install_common_components ;;
	option_provider_networks)
		option_provider_networks ;;
	option_self_serviece_networks)
		option_self_serviece_networks ;;
	finalize_configure_networking)
		finalize_configure_networking ;;
	exit)
		exit 0;;
	*)
		echo "Please type in a number Above"
		continue ;;
	esac
done
