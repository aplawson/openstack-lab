# This file contains bash functions that may be used by guest systems (VMs).

# Sourcing this file calls functions fix_path_env and source_deploy.

source "$LIB_DIR/functions.sh"
source "$LIB_DIR/functions-common-devstack"

# Make devstack's operating system identification work with nounset
function init_os_ident {
    if [[ -z "${os_PACKAGE:-""}" ]]; then
        GetOSVersion
    fi
}

function source_deploy {
    if [ -n "${VM_SHELL_USER:-}" ]; then
        # Already sourced
        return 0
    fi
    if mountpoint -q /vagrant; then
        source "$CONFIG_DIR/deploy.vagrant"
    else
        source "$CONFIG_DIR/deploy.osbash"
    fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# If our sudo user's PATH is preserved (and does not contain sbin dirs),
# some commands won't be found. Observed with Vagrant shell provisioner
# scripts using sudo after "su - vagrant".
# Adding to the path seems preferable to messing with the vagrant user's
# sudoers environment (or working with a separate Vagrant user).

function fix_path_env {
    if is_root; then return 0; fi
    if echo 'echo $PATH'|sudo sh|grep -q '/sbin'; then return 0; fi
    export PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function zero_empty_space {
    echo "Filling empty disk space with zeros"
    sudo dd if=/dev/zero of=/filler bs=1M 2>/dev/null || true
    sudo rm /filler
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For guest scripts to let osbash know they are running; used when osbashauto
# runs scripts inside of the VM (STATUS_DIR directory must be shared between
# host and VM).

function indicate_current_auto {
    if [ "${VM_SHELL_USER:-}" = "osbash" ]; then
        local scr_name=${1:-$(basename "$0")}
        local fpath=${2:-"/$STATUS_DIR/$scr_name.begin"}
        mkdir -p "$STATUS_DIR"
        touch "$fpath"
    fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Debug function to make a script halt execution until a tmp file is removed

function wait_for_file {
    # If no argument is passed, use empty string (to pass nounset option)
    local msg=${1-""}
    local wait_file=remove_to_continue
    [ -n "$msg" ] && wait_file=${wait_file}_${msg}
    touch "/tmp/$wait_file"
    while [ -e "/tmp/$wait_file" ]; do
        sleep 1
    done
}
#-------------------------------------------------------------------------------
# Copy stdin/stderr to log file
#-------------------------------------------------------------------------------

function exec_logpath {
    local log_path=$1

    # Append all stdin and stderr to log file
    exec > >(tee -a "$log_path") 2>&1
}

function exec_logfile {
    local log_dir=${1:-/home/$VM_SHELL_USER/log}

    # Default extension is log
    local ext=${2:-log}

    mkdir -p "$log_dir"

    # Log name based on name of running script
    local base_name=$(basename "$0" .sh)

    local prefix=$(get_next_prefix "$log_dir" "$ext")
    local log_name="${prefix}_$base_name.$ext"

    exec_logpath "$log_dir/$log_name"
}

#-------------------------------------------------------------------------------
# Functions that need to run as root
#-------------------------------------------------------------------------------

function as_root_fix_mount_vboxsf_link {
    local file=/sbin/mount.vboxsf
    if [ -L $file -a ! -e $file ]; then
        echo "$file is a broken symlink. Trying to fix it."
        shopt -s nullglob
        local new=(/opt/VBoxGuestAdditions*/lib/VBoxGuestAdditions)
        if [ -n "$new" ]; then
            ln -sv "$new" /usr/lib/VBoxGuestAdditions
        else
            return 1
        fi
    fi
}

function as_root_inject_sudoer {
    if grep -q "${VM_SHELL_USER}" /etc/sudoers; then
        echo "${VM_SHELL_USER} already in /etc/sudoers"
    else
        echo "${VM_SHELL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        echo "Defaults:${VM_SHELL_USER} !requiretty" >> /etc/sudoers
    fi
}

# Change to a regular user to execute a guest script (and log its output)

function as_root_exec_script {
    local script_path=$1
    local script_name="$(basename "$script_path" .sh)"

    echo "$(date) start $script_path"

    local prefix=$(get_next_prefix "$LOG_DIR" "auto")
    local log_path=$LOG_DIR/${prefix}_$script_name.auto

    su - "$VM_SHELL_USER" -c "bash $script_path" >"$log_path" 2>&1
    local rc=$?
    if [ $rc -ne 0 ]; then
        echo "$(date) ERROR: status $rc for $script_path" |
            tee >&2 -a "$LOG_DIR/error.log"
    else
        echo "$(date)  done"
    fi
    return $rc
}

#-------------------------------------------------------------------------------
# Root wrapper around devstack functions for manipulating config files
#-------------------------------------------------------------------------------

# Set an option in an INI file
# iniset config-file section option value
function iniset_sudo {
    local file=$1
    shift
    local tmpfile=$(mktemp)
    # Create a temporary copy, work on it, and copy it back into place
    sudo cp -fv "$file" "$tmpfile"
    echo >&2 iniset "$tmpfile" "$@"
    iniset "$tmpfile" "$@"
    cat "$tmpfile" | sudo tee "$file" >/dev/null
}

# Comment an option in an INI file
# inicomment config-file section option
function inicomment_sudo {
    local file=$1
    shift
    local tmpfile=$(mktemp)
    # Create a temporary copy, work on it, and copy it back into place
    sudo cp -fv "$file" "$tmpfile"
    echo >&2 inicomment "$tmpfile" "$@"
    inicomment "$tmpfile" "$@"
    cat "$tmpfile" | sudo tee "$file" >/dev/null
}

# Determinate is the given option present in the INI file
# ini_has_option config-file section option
function ini_has_option_sudo {
    local file=$1
    shift
    local tmpfile=$(mktemp)
    # Create a temporary copy, work on it
    sudo cp -fv "$file" "$tmpfile"
    echo >&2 ini_has_option "$tmpfile" "$@"
    ini_has_option "$tmpfile" "$@"
}

#-------------------------------------------------------------------------------
# Functions for manipulating config files without section
#-------------------------------------------------------------------------------

function iniset_sudo_no_section {
    local file=$1
    shift
    local tmpfile=$(mktemp)
    # Create a temporary copy, work on it, and copy it back into place
    sudo cp -fv "$file" "$tmpfile"
    iniset_no_section "$tmpfile" "$@"
    cat "$tmpfile" | sudo tee "$file" >/dev/null
}

# ini_has_option_no_section config-file option
function ini_has_option_no_section {
    local xtrace=$(set +o | grep xtrace)
    set +o xtrace
    local file=$1
    local option=$2
    local line
    line=$(sed -ne "/^$option[ \t]*=/ p;" "$file")
    $xtrace
    [ -n "$line" ]
}

# Set an option in an INI file
# iniset_no_section config-file option value
function iniset_no_section {
    local xtrace=$(set +o | grep xtrace)
    set +o xtrace
    local file=$1
    local option=$2
    local value=$3

    [[ -z $option ]] && return

    if ! ini_has_option_no_section "$file" "$option"; then
        # Add it
        sed -i -e "1 i\
$option = $value
" "$file"
    else
        local sep=$(echo -ne "\x01")
        # Replace it
        sed -i -e '/^'${option}'/ s'${sep}'^\('${option}'[ \t]*=[ \t]*\).*$'${sep}'\1'"${value}"${sep} "$file"
    fi
    $xtrace
}


#-------------------------------------------------------------------------------
# OpenStack helpers
#-------------------------------------------------------------------------------

function mysql_exe {
    local cmd="$1"
    echo "MySQL cmd: $cmd."
    mysql -u "root" -p"$DATABASE_PASSWORD" -e "$cmd"
}

function setup_database {
    local service=$1
    local db_user=$(service_to_db_user $service)
    local db_password=$(service_to_db_password $service)

    echo -n "Waiting for database server to come up."
    until mysql_exe quit >/dev/null 2>&1; do
        sleep 1
        echo -n .
    done
    echo

    mysql_exe "CREATE DATABASE $service"
    mysql_exe "GRANT ALL ON ${service}.* TO '$db_user'@'%' IDENTIFIED BY '$db_password';"
    mysql_exe "GRANT ALL ON ${service}.* TO '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
}

# Wait for neutron to come up. Due to a race during the operating system boot
# process, the neutron server sometimes fails to come up. We restart the
# neutron server if it does not reply for too long.
function wait_for_neutron {
    echo -n "Waiting for neutron to come up."
    local cnt=0
    local auth="source $CONFIG_DIR/demo-openstackrc.sh"
    until neutron net-list >/dev/null 2>&1; do
        if [ "$cnt" -eq 10 ]; then
            echo
            echo "ERROR No response from neutron. Restarting neutron-server."
            node_ssh controller-mgmt "$auth; sudo service neutron-server restart"
            echo -n "Waiting for neutron to come up."
        elif [ "$cnt" -eq 20 ]; then
            echo
            echo "ERROR neutron does not seem to come up. Aborting."
            exit 1
        fi
        echo -n .
        sleep 1
        cnt=$((cnt + 1))
    done
    echo
}

# Wait for keystone to come up
function wait_for_keystone {
    echo -n "Waiting for keystone to come up."
    until openstack user list >/dev/null 2>&1; do
        echo -n .
        sleep 1
    done
    echo
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Users for service-specific MySQL databases

function service_to_db_user {
    local service_name=$1
    echo "${service_name}User"
}

function service_to_db_password {
    local service_name=$1
    echo "${service_name}Pass"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Service-specific users in keystone

function service_to_user_name {
    local service_name=$1
    echo "${service_name}"
}

function service_to_user_password {
    local service_name=$1
    echo "${service_name}_pass"
}

#-------------------------------------------------------------------------------
# Network configuration
#-------------------------------------------------------------------------------

function hostname_to_ip {
    local host_name=$1
    getent hosts "$host_name"|awk '{print $1}'
}

function config_network {
    init_os_ident
    if is_ubuntu; then
        source "$LIB_DIR/functions.ubuntu.sh"
    else
        source "$LIB_DIR/functions.fedora.sh"
    fi

    netcfg_init

    # Get network interface configuration (NET_IF_?) for this node
    unset -v NET_IF_0 NET_IF_1 NET_IF_2 NET_IF_3
    get_node_netif_config "$(hostname)"

    local index
    local iftype
    for index in "${!NODE_IF_TYPE[@]}"; do
        iftype=${NODE_IF_TYPE[index]}
        config_netif "$iftype" "$index" "${NODE_IF_IP[index]}"
    done
}

#-------------------------------------------------------------------------------
# ssh wrapper functions
#-------------------------------------------------------------------------------

function no_chk_ssh {
    echo >&2 "ssh $@"
    # Options set to disable strict host key checking and related messages.
    ssh \
        -o "UserKnownHostsFile /dev/null" \
        -o "StrictHostKeyChecking no" \
        -o LogLevel=error \
        "$@"
}

# ssh from one node VM to another node in the cluster
function node_ssh {
    no_chk_ssh -i "$HOME/.ssh/osbash_key" "$@"
}

#-------------------------------------------------------------------------------
fix_path_env
source_deploy
#-------------------------------------------------------------------------------

# vim: set ai ts=4 sw=4 et ft=sh:
