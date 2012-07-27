#!/bin/bash

cd `dirname $0`

source scripts/.utils.sh || { echo -e "\033[31mUnable to include necessary .utils.sh script. Exiting\033[0m"; exit -1; }
source scripts/imageLib.sh || { echo -e "\033[31mUnable to include necessary imageLib.sh script. Exiting\033[0m"; exit -1; }
source scripts/vmLib.sh || { echo -e "\033[31mUnable to include necessary vmLib.sh script. Exiting\033[0m"; exit -1; }

function usage {
  success "######################################################################"
  success "#                           KVM utils.                               #"
  success "#          Scripts to manage virtual machine environments            #"
  success "######################################################################"
  if [ $# -eq 1 ]; then
    type help_$1 &>/dev/null || fail "No help available for action $1."
    help_$1
  else
    echo "Usage: $0 <action> [arguments]"
    echo "Available actions:"
    echo "  -> create_based_image"
    echo "  -> create_image"
    echo "  -> create_vm"
    echo "  -> help"
    echo "  -> info"
    echo "  -> list"
    echo "  -> list_images"
    echo "  -> rebase_image"
    echo "  -> start_vm"
    echo "  -> quickstart_vm"
    echo "  -> test_support"
    echo "To see the help of each action in particular run $0 help <action>"
  fi
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
  printf "Select the number of CPUs allocated to the VM (default: 1): " && read cpus
  [ -n "$cpus" ] || cpus="1"
  echo "CPUS='$cpus'" >> $file
  printf "Select the amount of RAM allocated to the VM (default: 500MB): " && read ram
  [ -n "$ram" ] || ram="500"
  echo "MEMORY='$ram'" >> $file
  printf "Select the VM image file (mandatory): " && read image
  image="/home/$user/.kvm/images/$image.qcow2"
  [ -e $image ] || { error "VM image '$image' was not found."; rm $file; return 1; }
  echo "IMAGE=$image" >> $file
  printf "Select the cdrom iso file (default: none): " && read cdrom
  echo "CDROM='-cdrom $cdrom'" >> $file
  printf "Select the mac address of the VM (default: random): " && read mac
  echo "MACADDRESS='$mac'" >> $file
  success "Created a new VM Machine named $name"
}

function list {
  local user=`whoami`
  local conf_dir="/home/$user/.kvm/configurations"
  echo "Available VM Machines:"
  ls $conf_dir
}

function list_images {
  local user=`whoami`
  local img_dir="/home/$user/.kvm/images"
  echo "Available VM images"
  ls $img_dir
}

function info {
  local vm_name=$1
  [ -n "$vm_name" ] || fail "No virtual machine configuration name was specified."
  local user=`whoami`
  local prop_file="/home/$user/.kvm/configurations/$vm_name.properties"
  [ -e $prop_file ] || fail "No virtual machine configuration named $vm_name was found on /home/$user/.kvm/configurations"
  source $prop_file || fail "Failed to read info of virtual machine $vm_name"
  success "Details of virtual machine $vm_name"
  echo -e "Number of CPUs:\t$CPUS" 
  echo -e "Memory:\t\t$MEMORY"
  echo -e "Cdrom file:\t$CDROM"
  echo -e "MAC address:\t$MACADDRESS"
  qemu-img info $IMAGE
}

ACTION=$1
shift
case $ACTION in
  'test_support')
    test_support $*
  ;;
  'create_image')
    create_image $*
  ;;
  'create_based_image')
    create_based_image $*
  ;;
  'rebase_image')
    rebase_image $*
  ;;
  'start_vm')
    start_vm $*
  ;;
  'quickstart_vm')
    quickstart_vm $*
  ;;
  'create_vm')
    create_vm $*
  ;;
  'list')
    list $*
  ;;
  'list_images')
    list_images $*
  ;;
  'info')
    info $*
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
