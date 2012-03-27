#!/bin/bash

cd `dirname $0`

source scripts/.utils.sh || { echo -e "\033[31mUnable to include necessary .utils.sh script. Exiting\033[0m"; exit -1; }
source scripts/imageLib.sh || { echo -e "\033[31mUnable to include necessary imageLib.sh script. Exiting\033[0m"; exit -1; }
source scripts/vmLib.sh || { echo -e "\033[31mUnable to include necessary vmLib.sh script. Exiting\033[0m"; exit -1; }

function usage {
  echo "Usage: $0 <action> [arguments]"
  echo "Available actions:"
  echo "  test_support"
  echo "  create_image"
  echo "  create_based_image"
  echo "  rebase_image"
  echo "  start_vm"
  echo "  create_vm"
  echo "  list"
  echo "  info"
}

function create_vm {
  echo "Configuring a new VM machine..."
  local user=`whoami`
  local conf_dir="/home/$user/.kvm/configurations"
  mkdir -p $conf_dir
  echo "Configurations will be stored on $conf_dir"
  local name=$1
  [ -n "$name" ] || { printf "Select the name of the VM machine: "; read name; }
  local file=$conf_dir/$name.properties
  [ ! -e $file ] || { error "A VM machine named $name already exists."; return 1; }
  touch $file || { error "Unable to create configuration file $file"; return 1; }
  printf "Select the number of CPUs allocated to the VM: " && read cpus
  echo "CPUS='$cpus'" >> $file
  printf "Select the amount of RAM allocated to the VM: " && read ram
  echo "MEMORY='$ram'" >> $file
  printf "Select the VM image file: " && read image
  echo "IMAGE=$image" >> $file
  printf "Select the cdrom iso file: " && read cdrom
  echo "CDROM='-cdrom $cdrom'" >> $file
  printf "Select the mac address of the VM: " && read mac
  echo "MACADDRESS='$mac'" >> $file
  success "Created a new VM Machine named $name"
}

function list {
  local user=`whoami`
  local conf_dir="/home/$user/.kvm/configurations"
  echo "Available VM Machines:"
  ls $conf_dir
}

function info {
  local vm_name=$1
  [ -n "$vm_name" ] || fail "No virtual machine configuration name was specified."
  local user=`whoami`
  local prop_file="/home/$user/.kvm/configurations/$vm_name.properties"
  [ -e $prop_file ] || fail "No virtual machine configuration named $vm_name was found on /home/$user/.kvm/configurations"
  source $prop_file || fail "Failed to read info of virtual machine $vm_name"
  echo "Details of virtual machine $vm_name"
  echo -e "Number of CPUs:\t$CPUS" 
  echo -e "Memory:\t\t$MEMORY"
  echo -e "Image file:\t$IMAGE"
  echo -e "Cdrom file:\t$CDROM"
  echo -e "MAC address:\t$MACADDRESS"
}

ACTION=$1
shift

type $ACTION &>/dev/null && $ACTION $* || { error "Unknown option $ACTION"; usage; exit -1; }
