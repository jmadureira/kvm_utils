#!/bin/bash

#
# Starts a VM machine using the configurations provided by the given properties file.
# Arguments:
#  prop_file => the properties file to load
#
function start_vm {
  local prop_file=$1
  [ -n "$prop_file" ] || { error "No configuration file was provided."; return 1; }
  [ -e $prop_file ] || { error "Unable to find the properties file $prop_file."; return 1; }
  source $prop_file || { error "Failed to load properties file '$prop_file'"; return 1; }
  # Create tap interface so that the script /etc/qemu-ifup can bridge it
  # before qemu starts
  local user_id=`whoami`
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

