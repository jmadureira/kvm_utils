#!/bin/bash

cd `dirname $0`

source .utils.sh || { echo -e "\033[31mUnable to include necessary utils.sh script. Exiting\033[0m"; exit -1; }

function usage {
  if [ $# -eq 1 ]; then
    type help_$1 &>/dev/null || fail "Unkown command $1."
    help_$1
  else
    echo "Script responsible for handling the virtual machines networking."
    echo "Available actions:"
    echo "start"
    echo "stop"
    echo "For details regarding each particular command run: $0 help <command>."
  fi
}

function help_start {
  echo "Sets up the network to be used by the virtual machines."
  echo "Usage:"
  echo "$0 start <name of the bridge> [bridge ip address] [bridge net mask]"
}

function start_bridge {
  local bridge_name=$1
  local bridge_ip=$2
  local bridge_mask=$3
  [ -n "$bridge_name" ] || { bridge_name='br0'; warning "Bridge name not set. Using default $bridge_name."; }
  [ -n "$bridge_ip" ] || { bridge_ip='129.168.100.1'; warning "Bridge ip address not set. Using default $bridge_ip."; }
  [ -n "$bridge_mask" ] || { bridge_mask='255.255.255.0'; warning "Bridge net mask not set. Using default $bridge_mask."; }
  setup_bridge $bridge_name $bridge_ip $bridge_mask || fail "Bridge setup failed."
  setup_dns $bridge_name $bridge_ip '129.168.100.50,129.168.100.150,forever'
  local firewall_file='firehol.conf'
  echo "Using $firewall_file as the firehol configuration file"
  start_firehol $firewall_file
}

function help_stop {
  echo "Tears down all the network configurations used by the virtual machines."
  echo "Usage:"
  echo "$0 stop <name of the bridge>"
}

function stop_bridge {
  local bridge_name=$1
  teardown_dns $bridge_name
  teardown_bridge $bridge_name
  stop_firehol
}

[ $# -gt 0 ] || { error "Incorrect number of arguments."; usage; exit -1; }

ACTION=$1
shift
case $ACTION in
  'start')
    start_bridge $*
  ;;
  'stop')
    stop_bridge $*
  ;;
  'help')
    usage $*
  ;;
  *)
    error "Unknown option $1"
    usage
    exit -1
  ;;
esac

