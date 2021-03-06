#!/usr/bin/env bash
set -o errexit -o nounset
TOP_DIR=$(cd "$(dirname "$0")/.." && pwd)
source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

#-------------------------------------------------------------------------------
# Controller setup

DB_IP=$(get_node_ip_in_network "$(hostname)" "mgmt")
echo "Will bind MySQL server to $DB_IP."

#------------------------------------------------------------------------------
# Install and configure the database server
# http://docs.openstack.org/kilo/install-guide/install/apt/content/ch_basic_environment.html
#------------------------------------------------------------------------------

echo "Sourced MySQL password from credentials: $DATABASE_PASSWORD"
sudo debconf-set-selections  <<< 'mysql-server mysql-server/root_password password '$DATABASE_PASSWORD''
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$DATABASE_PASSWORD''

echo "Installing MySQL."
sudo apt-get install -y mariadb-server python-mysqldb

echo "Creating /etc/mysql/conf.d/mysqld_openstack.cnf."

echo '[mysqld]' | sudo tee -a /etc/mysql/conf.d/mysqld_openstack.cnf


echo "Configuring MySQL to accept requests by other nodes."

conf=/etc/mysql/conf.d/mysqld_openstack.cnf
# Enable access by other nodes via the management network
iniset_sudo $conf mysqld bind-address "$DB_IP"

# Enable InnoDB
iniset_sudo $conf mysqld default-storage-engine innodb
iniset_sudo $conf mysqld innodb_file_per_table 1

# Enable UTF-8 character set and UTF-8 collation by default
iniset_sudo $conf mysqld collation-server utf8_general_ci
iniset_sudo $conf mysqld init-connect "'SET NAMES utf8'"
iniset_sudo $conf mysqld character-set-server utf8

echo "Restarting MySQL service."
# Close the file descriptor or the script will hang due to open ssh connection
sudo service mysql restart 2>/dev/null

# TODO(rluethi) do we need mysql_secure_installation?
# XXX --use-default only in MySQL 5.7.4+ (Ubuntu 12.04 LTS: MySQL 5.5)
# mysql_secure_installation --use-default
