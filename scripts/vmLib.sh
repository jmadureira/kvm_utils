#!/bin/bash

#
# Load the given properties file. The function will first look on the user's kvm configuration directory. If none is found it will fallback
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

function help_start_vm {
  echo "Starts a VM machine using the configurations provided by the given properties file."
  echo "Usage:"
  echo "	$0 start_vm <VM name>"
  echo "Arguments:"
  echo "	VM name => name or path to the vm properties file."
  echo "Examples:"
  echo "	$0 start_vm base_ubuntu"
  echo "	$0 start_vm redhat_base.properties"
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

function help_quickstart_vm {
  echo "Bootstrap of a new VM machine based on an already existing configuration."
  echo "This action will execute the following actions:"
  echo "  1 - load the properties of the base VM."
  echo "  2 - create a snapshot of the base VM image."
  echo "  3 - configure the new VM."
  echo "  4 - launch the new VM."
  echo "Usage:"
  echo "	$0 quickstart_vm <VM name> <Original VM name>"
  echo "Arguments:"
  echo "	VM name => name of the new VM."
  echo "	Original VM name => Name of the base VM image from where the new image will be created."
  echo "Examples:"
  echo "	$0 quickstart_vm postgresql base_ubuntu"
}

function quickstart_vm {
  [ -n "$1" ] || { error "No VM name was provided."; return 1; }
  local vm_name=$1
  [ -n "$2" ] || { error "No base VM name was provided."; return 1; }  
  load_properties $2 || return 1
  local orig_image=`basename $IMAGE | sed 's/\..\{5\}$//'`
  echo "Creating base image named $vm_name from $orig_image"
  create_based_image $vm_name $orig_image -f
  echo "Configuring the new VM machine..."
  local user=`whoami`
  local conf_dir="/home/$user/.kvm/configurations"
  local file=$conf_dir/$vm_name.properties
  if [ -e $file ]; then
    warning "A VM machine named $name already exists. Its configuration will remain unchanged."
  else
    touch $file || { error "Unable to create configuration file $file"; return 1; }
    echo "CPUS='$CPUS'" >> $file
    echo "MEMORY='$MEMORY'" >> $file
    local image="/home/$user/.kvm/images/$vm_name.qcow2"
    echo "IMAGE=$image" >> $file
    echo "CDROM=''" >> $file
    local macaddress=`echo -n 00-60-2F; dd bs=1 count=3 if=/dev/random 2>/dev/null |hexdump -v -e '/1 "-%02X"'`
    echo "MACADDRESS='$macaddress'" >> $file
  fi
  start_vm $vm_name
}
