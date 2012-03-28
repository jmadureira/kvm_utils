#!/bin/bash

USER=`whoami`
IMAGE_DIR="/home/$USER/.kvm/images/"

function help_create_image {
  echo "Creates a new virtual image. The new image will be stored on $IMAGE_DIR."
  echo "Usage:"
  echo "	$0 create_image <name of the image> <image size>"
  echo "Example:"
  echo "	$0 create_image base_ubuntu 10G"
}

function create_image {
  local name=$1
  local size=$2
  mkdir -p $IMAGE_DIR
  echo "Images will be stored on $IMAGE_DIR."
  [ -d $IMAGE_DIR ] || { error "Unable to create image $name. Images dir $IMAGE_DIR does not exist."; return 1; }
  [ -n "$name" ] || { error "No image name was given."; return 1; }
  [ -e "$dir/$name.qcow2" ] && error "An image named $name already exists." && return 1
  [ -n "$size" ] || { error "No image size was given."; return 1; }
  echo "Creating an image file named $name with $size"
  cd $IMAGE_DIR
  qemu-img create -f qcow2 $name.qcow2 $size
  cd -
  success "Image $IMAGE_DIR/$name.qcow2 created successfully."
}

function help_create_based_image {
  echo "Creates a new snapshot based on an existing virtual machine image."
  echo "Both images reside on '$IMAGE_DIR'"
  echo "Usage:"
  echo "	$0 create_based_image <name of the new image> <base image file>"
  echo "Example:"
  echo "	$0 create_based_image ubuntu_postgres base_ubuntu"
}

function create_based_image {
  local name=$1
  local base_file=$2
  mkdir -p $IMAGE_DIR
  echo "Images will be stored on $IMAGE_DIR."
  [ -d $IMAGE_DIR ] || { error "Unable to create image $name. Images dir $IMAGE_DIR does not exist."; return 1; }
  [ -n "$name" ] || { error "No image name was given."; return 1; }
  [ -e "$IMAGE_DIR/$name.qcow2" ] && error "An image named $name already exists on $IMAGE_DIR." && return 1
  [ -n "$base_file" ] || { error "No base image name was given."; return 1; }
  [ -e "$IMAGE_DIR/$base_file.qcow2" ] || { error "Base image file '$base_file' was not found on $IMAGE_DIR."; return 1; }
  echo "Creating an image file named $name based on $base_file"
  cd $IMAGE_DIR
  qemu-img create -b $base_file.qcow2 -f qcow2 $name.qcow2 || { cd -; fail "Failed to create image."; }
  cd -
  success "Image $IMAGE_DIR/$name.qcow2 created successfully."
}

function rebase_image {
  local orig_name=$1
  local new_name=$2
  mkdir -p $IMAGE_DIR
  echo "Images will be stored on $IMAGE_DIR."
  [ -d $IMAGE_DIR ] || { error "Unable to create image $new_name. Images dir $IMAGE_DIR does not exist."; return 1; }
  [ -n "$orig_name" ] || { error "No original image name was given."; return 1; }
  [ -e "$IMAGE_DIR/$orig_name.qcow2" ] || { error "Original image file '$orig_name' was not found on $IMAGE_DIR."; return 1; }
  [ -n "$new_name" ] || { error "No new image name was given."; return 1; }
  [ -e "$IMAGE_DIR/$new_name.qcow2" ] && error "An image named $new_name already exists on $IMAGE_DIR." && return 1
  echo "Creating an image file named $name based on $base_file"
  cd $IMAGE_DIR
  qemu-img convert $orig_name -O qcow2 $new_name.qcow2
  cd -
}
