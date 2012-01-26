#!/bin/bash

#
# Load the given properties file. The function will first look on the user's kvm configuration directory. If none is found it will fallbak
# to the current directory. Fails if the file isn't found anywhere.
# Arguments:
#  prop_file => the properties file to load. Can be either <name>.properties or just <name>.
#
function load_properties {
  [ -n "$1" ] || { error "No configuration file was provided."; return 1; }
  local prop_file=`echo "$1" | sed 's/\(.*\).properties$/\1/'`
  prop_file=$prop_file.properties
  local user_id=`whoami`
  if [ -e "/home/$user_id/.kvm/configurations/$prop_file" ]; then
    echo "Loading properties file from /home/$user_id/.kvm/configurations/$prop_file"
    source "/home/$user_id/.kvm/configurations/$prop_file" || { error "Failed to load properties file '/home/$user_id/.kvm/configurations/$prop_file'"; return 1; }
  else
    warning "$prop_file was not found on /home/$user_id/.kvm/configurations"
    if [ -e $prop_file ]; then
      echo "Loading properties file from `dirname $prop_file`"
      source $prop_file || { error "Failed to load properties file '$prop_file'"; return 1; }
    else  
      error "Unable to find the properties file $prop_file."
      return 1
    fi
  fi
  return 0
}

#
# Starts a VM machine using the configurations provided by the given properties file.
# Arguments:
#  prop_file => the properties file to load
#
function start_vm {
  load_properties $* || return 1
  local user_id=`whoami`
  # Create tap interface so that the script /etc/qemu-ifup can bridge it
  # before qemu starts
  local iface=`sudo tunctl -b -u $user_id`
  # Start kvm
  local qemu_up=`find . -name 'qemu-ifup'`
  [ -e $qemu_up ] || { error "Unable to find qemu-ifup script needed to start the VM"; return 1; }
  local qemu_down=`find . -name 'qemu-ifdown'`
  [ -e $qemu_down ] || { error "Unable to find qemu-ifdown script needed to start the VM"; return 1; }
  [ -e $IMAGE ] || { error "Unable to find the image file '$IMAGE'."; return 1; }
  local kvm="kvm -smp $CPUS -m $MEMORY -drive file=$IMAGE,if=virtio,boot=on $CDROM -net nic,model=virtio,macaddr=$MACADDRESS -net tap,ifname=$iface,script=$qemu_up,downscript=$qemu_down -net dump,file=/tmp/vm0.pcap"
  echo "Running $kvm"
  $kvm
  # kvm has stopped - remove tap interface
  sudo tunctl -d $iface #&> /dev/null
}

