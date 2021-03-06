#!/usr/bin/env bash
set -o errexit -o nounset
TOP_DIR=$(cd "$(dirname "$0")/.." && pwd)
source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"
exec_logfile

indicate_current_auto

#------------------------------------------------------------------------------
# Set up OpenStack Networking (neutron) for controller node.
# http://docs.openstack.org/kilo/install-guide/install/apt/content/neutron-controller-node.html
#------------------------------------------------------------------------------

echo "Setting up database for neutron."
setup_database neutron

source "$CONFIG_DIR/admin-openstackrc.sh"

neutron_admin_user=$(service_to_user_name neutron)
neutron_admin_password=$(service_to_user_password neutron)

# Wait for keystone to come up
wait_for_keystone

echo "Creating neutron user and giving it admin role under service tenant."
openstack user create \
    --password "$neutron_admin_password" \
    "$neutron_admin_user"

openstack role add \
    --project "$SERVICE_PROJECT_NAME" \
    --user "$neutron_admin_user" \
    "$ADMIN_ROLE_NAME"

echo "Registering neutron with keystone so that other services can locate it."
openstack service create \
    --name neutron \
    --description "OpenStack Networking" \
    network

openstack endpoint create \
    --publicurl http://controller-api:9696 \
    --adminurl http://controller-mgmt:9696 \
    --internalurl http://controller-mgmt:9696 \
    --region "$REGION" \
    network

echo "Installing neutron for controller node."
sudo apt-get install -y \
    neutron-server neutron-plugin-ml2 python-neutronclient

echo "Configuring neutron for controller node."

function get_database_url {
    local db_user=$(service_to_db_user neutron)
    local db_password=$(service_to_db_password neutron)
    local database_host=controller-mgmt

    echo "mysql://$db_user:$db_password@$database_host/neutron"
}

database_url=$(get_database_url)

echo "Setting database connection: $database_url."
conf=/etc/neutron/neutron.conf
iniset_sudo $conf database connection "$database_url"

# Configure AMQP parameters
iniset_sudo $conf DEFAULT rpc_backend rabbit

iniset_sudo $conf oslo_messaging_rabbit rabbit_host controller-mgmt
iniset_sudo $conf oslo_messaging_rabbit rabbit_userid openstack
iniset_sudo $conf oslo_messaging_rabbit rabbit_password "$RABBIT_PASSWORD"

# Configuring [DEFAULT] section
iniset_sudo $conf DEFAULT auth_strategy keystone

# Configuring [keystone_authtoken] section
iniset_sudo $conf keystone_authtoken auth_uri http://controller-mgmt:5000
iniset_sudo $conf keystone_authtoken auth_url http://controller-mgmt:35357
iniset_sudo $conf keystone_authtoken auth_plugin password
iniset_sudo $conf keystone_authtoken project_domain_id default
iniset_sudo $conf keystone_authtoken user_domain_id default
iniset_sudo $conf keystone_authtoken project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf keystone_authtoken username "$neutron_admin_user"
iniset_sudo $conf keystone_authtoken password "$neutron_admin_password"
iniset_sudo $conf keystone_authtoken admin_tenant_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf keystone_authtoken admin_user "$neutron_admin_user"
iniset_sudo $conf keystone_authtoken admin_password "$neutron_admin_password"

# Configure network plugin parameters
iniset_sudo $conf DEFAULT core_plugin ml2
iniset_sudo $conf DEFAULT service_plugins router
iniset_sudo $conf DEFAULT allow_overlapping_ips True

nova_admin_user=$(service_to_user_name nova)
nova_admin_password=$(service_to_user_password nova)

# Configure nova related parameters
iniset_sudo $conf DEFAULT notify_nova_on_port_status_changes True
iniset_sudo $conf DEFAULT notify_nova_on_port_data_changes True
iniset_sudo $conf DEFAULT nova_url http://controller-mgmt:8774/v2

iniset_sudo $conf nova auth_url http://controller-mgmt:35357
iniset_sudo $conf nova auth_plugin password
iniset_sudo $conf nova project_domain_id default
iniset_sudo $conf nova user_domain_id default
iniset_sudo $conf nova region_name "$REGION"
iniset_sudo $conf nova project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf nova username "$nova_admin_user"
iniset_sudo $conf nova password "$nova_admin_password"
iniset_sudo $conf DEFAULT verbose True

echo "Configuring the OVS plug-in to use GRE tunneling."
conf=/etc/neutron/plugins/ml2/ml2_conf.ini

# Edit the [ml2] section.
iniset_sudo $conf ml2 type_drivers flat,vlan,gre,vxlan
iniset_sudo $conf ml2 tenant_network_types gre
iniset_sudo $conf ml2 mechanism_drivers openvswitch

# Edit the [ml2_type_gre] section.
iniset_sudo $conf ml2_type_gre tunnel_id_ranges 1:1000

# Edit the [securitygroup] section.
iniset_sudo $conf securitygroup enable_security_group True
iniset_sudo $conf securitygroup enable_ipset True
iniset_sudo $conf securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

echo "Configure Compute to use Networking"
conf=/etc/nova/nova.conf
iniset_sudo $conf DEFAULT network_api_class nova.network.neutronv2.api.API
iniset_sudo $conf DEFAULT security_group_api neutron
iniset_sudo $conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
iniset_sudo $conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

iniset_sudo $conf neutron url http://controller-mgmt:9696
iniset_sudo $conf neutron auth_strategy keystone
iniset_sudo $conf neutron admin_auth_url http://controller-mgmt:35357/v2.0
iniset_sudo $conf neutron admin_tenant_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf neutron admin_username "$neutron_admin_user"
iniset_sudo $conf neutron admin_password "$neutron_admin_password"

# service_neutron_metadata_proxy, neutron_metadata_proxy_shared_secret from:
# http://docs.openstack.org/kilo/install-guide/install/apt/content/neutron-network-node.html
iniset_sudo $conf neutron service_metadata_proxy True
iniset_sudo $conf neutron metadata_proxy_shared_secret "$METADATA_SECRET"

sudo neutron-db-manage \
    --config-file /etc/neutron/neutron.conf \
    --config-file /etc/neutron/plugins/ml2/ml2_conf.ini \
    upgrade head

echo "Restarting nova services."
sudo service nova-api restart

echo "Restarting neutron service."
sudo service neutron-server restart

echo "Verifying operation."
until neutron ext-list >/dev/null 2>&1; do
    sleep 1
done
neutron ext-list
