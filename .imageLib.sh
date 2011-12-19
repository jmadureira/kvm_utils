#!/bin/bash

function create_image {
  local name=$1
  local size=$2
  local user=`whoami`
  local dir="/home/$user/.kvm/images"
  mkdir -p $dir
  echo "Images will be stored on $dir."
  [ -d $dir ] || { error "Unable to create image $name. Images dir $dir does not exist."; return 1; }
  [ -n "$name" ] || { error "No image name was given."; return 1; }
  [ -e "$dir/$name.qcow2" ] && error "An image named $name already exists." && return 1
  [ -n "$size" ] || { error "No image size was given."; return 1; }
  echo "Creating an image file named $name with $size"
  cd $dir
  qemu-img create -f qcow2 $name.qcow2 $size
  cd -
}

function help_create_based_image {
  echo "Creates a new snapshot based on an existing virtual machine image."
  local user=`whoami`
  local dir="/home/$user/.kvm/images"
  echo "Both images reside on '$dir'"
  echo "Usage:"
  echo "$0 create_based_image <name of the new image> <base image file>"
  echo "Example:"
  echo "$0 create_based_image ubuntu_postgres base_ubuntu"
}

function create_based_image {
  local name=$1
  local base_file=$2
  local user=`whoami`
  local dir="/home/$user/.kvm/images"
  mkdir -p $dir
  echo "Images will be stored on $dir."
  [ -d $dir ] || { error "Unable to create image $name. Images dir $dir does not exist."; return 1; }
  [ -n "$name" ] || { error "No image name was given."; return 1; }
  [ -e "$dir/$name.qcow2" ] && error "An image named $name already exists on $dir." && return 1
  [ -n "$base_file" ] || { error "No base image name was given."; return 1; }
  [ -e "$dir/$base_file.qcow2" ] || { error "Base image file '$base_file' was not found on $dir."; return 1; }
  echo "Creating an image file named $name based on $base_file"
  cd $dir
  qemu-img create -b $base_file.qcow2 -f qcow2 $name.qcow2 || { cd -; fail "Failed to create image."; }
  cd -
  success "Image $dir/$name.qcow2 created successfully."
}

function rebase_image {
  local orig_name=$1
  local new_name=$2
  local user=`whoami`
  local dir="/home/$user/.kvm/images"
  mkdir -p $dir
  echo "Images will be stored on $dir."
  [ -d $dir ] || { error "Unable to create image $new_name. Images dir $dir does not exist."; return 1; }
  [ -n "$orig_name" ] || { error "No original image name was given."; return 1; }
  [ -e "$dir/$orig_name.qcow2" ] || { error "Original image file '$orig_name' was not found on $dir."; return 1; }
  [ -n "$new_name" ] || { error "No new image name was given."; return 1; }
  [ -e "$dir/$new_name.qcow2" ] && error "An image named $new_name already exists on $dir." && return 1
  echo "Creating an image file named $name based on $base_file"
  cd $dir
  qemu-img convert $orig_name -O qcow2 $new_name.qcow2
  cd -
}
