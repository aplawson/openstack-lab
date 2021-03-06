#!/usr/bin/env bash
set -o errexit -o nounset
TOP_DIR=$(cd "$(dirname "$0")/.." && pwd)
source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/openstack"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

# Download CirrOS image
function get_cirros {
    local file_name=$(basename $CIRROS_URL)
    local remote_dir=$(dirname $CIRROS_URL)
    local md5_f=$file_name.md5sum

    mkdir -p "$IMG_DIR"

    # Download to IMG_DIR to cache the data if the directory is shared
    # with the host computer.
    if [ ! -f "$IMG_DIR/$md5_f" ]; then
        wget -O - "$remote_dir/MD5SUMS"|grep "$file_name" > "$IMG_DIR/$md5_f"
    fi

    if [ ! -f "$IMG_DIR/$file_name" ]; then
        wget --directory-prefix="$IMG_DIR" "$CIRROS_URL"
    fi

    # Make sure we have image and MD5SUM on the basedisk.
    if [ "$IMG_DIR" != "$HOME/img" ]; then
        mkdir -p "$HOME/img"
        cp -a "$IMG_DIR/$file_name" "$IMG_DIR/$md5_f" "$HOME/img"
    fi

    cd "$HOME/img"
    md5sum -c "$HOME/img/$md5_f"
    cd -
}
get_cirros

function get_keystone_httpd_files {

    wget --directory-prefix "$HOME" -O "keystone.py" "http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo"
}
get_keystone_httpd_files

function apt_download {

    sudo apt-get install -y --download-only "$@"

}

# Download packages for all nodes

# MySQL, RabbitMQ
apt_download mariadb-server python-mysqldb rabbitmq-server

# Other dependencies
apt_download python-argparse

# Keystone
apt_download keystone python-openstackclient apache2 \
    libapache2-mod-wsgi memcached python-memcache

# Glance
apt_download glance python-glanceclient

# Nova Controller
apt_download nova-api nova-cert nova-conductor nova-consoleauth \
    nova-novncproxy nova-scheduler python-novaclient

# Neutron Controller
apt_download neutron-server neutron-plugin-ml2 neutron-lbaas-agent \
    python-neutronclient

# Cinder Controller
apt_download cinder-api cinder-scheduler python-cinderclient

# Horizon
apt_download openstack-dashboard

# Cinder Volumes
apt_download lvm2 cinder-volume

# Nova Compute
apt_download nova-compute-qemu qemu sysfsutils

# Neutron Compute
apt_download neutron-common neutron-plugin-ml2 \
    neutron-plugin-openvswitch-agent openvswitch-datapath-dkms

# Neutron Network
apt_download neutron-common neutron-plugin-ml2 \
    neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent

# Heat
apt_download heat-api heat-api-cfn heat-engine python-heatclient

# Ceilometer
apt_download mongodb-server mongodb-clients python-pymongo \
    ceilometer-api ceilometer-collector ceilometer-agent-central \
    ceilometer-agent-notification ceilometer-alarm-evaluator \
    ceilometer-alarm-notifier ceilometer-agent-compute \
    python-ceilometerclient
