#!/bin/bash

#
# Sets up a network bridge.
# Arguments:
# 1 - name of the bridge
# 2 - ip address of the bridge
# 3 - bridge mask
# Returns 1 if any of these arguments is missing or the setup failed.
#
function setup_bridge {
  local name=$1
  local address=$2
  local mask=$3
  [ -n "$name" ] || { error "No bridge name was given."; return 1; }
  [ -n "$address" ] || { error "No bridge ip address was given."; return 1; }
  [ -n "$mask" ] || { error "No bridge netmask was given."; return 1; }
  echo "Setting up a bridge named $name on address $address with netmask $mask."
  sudo brctl addbr $name || return 1
  sudo ifconfig $name $address netmask $mask up || return 1
}

#
# Removes a network bridge.
# Arguments:
# 1 - name of the bridge
#
function teardown_bridge {
  local name=$1
  [ -n "$name" ] || { error "No bridge name was given."; return 1; }
  echo "Stopping bridge $name"
  sudo ifconfig $name down
  sudo brctl delbr $name
}

#
# Sets up dnsmasq.
# Arguments:
# 1 - name of the dns service name. This is needed so that later we can easily stop the service.
# 2 - ip address were the service will be listening to.
# 3 - ip address range to be given to clients.
# 4 - location of a configuration directory whose files will be read by dnsmasq.
#
function setup_dns {
  local name=$1
  local address=$2
  local range=$3
  local confdir=$4
  [ -n "$name" ] || { error "No DNS service name was given."; return 1; }
  [ -n "$address" ] || { error "No DNS binding address was given."; return 1; }
  [ -n "$range" ] || { error "No DHCP range was given."; return 1; }
  echo "Starting dnsmasq on address $address named $name and using configuration files located on $confdir."
  sudo dnsmasq -q -a $address --conf-dir=$confdir --dhcp-range=$range --pid-file=/tmp/$name-dnsmasq.pid || return 1
}

#
# Stops dnsmasq
# Arguments:
# 1 - the name of the service
#
function teardown_dns {
  local name=$1
  [ -n "$name" ] || { error "No DNS service name was given."; return 1; }
  echo "Stopping dnsmasq named $name."
  sudo kill -15 `cat /tmp/$name-dnsmasq.pid`
  sudo rm /tmp/$name-dnsmasq.pid
}

#
# Restarts firehol using the provided configuration file.
#
function start_firehol {
  local file=$1
  [ -n "$file" ] || { error "No firehol configuration file was provided."; return 1; }
  [ -f "$file" ] || { error "Firehol configuration file '$file' was not found."; return 1; }
  sudo firehol $file start
}

#
# Restarts firehol using the default configuration.
#
function stop_firehol {
  echo "Restoring original firehol configurations."
  sudo firehol /etc/firehol/firehol.conf start
}

