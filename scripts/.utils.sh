#!/bin/bash

#
# Prints a red colored error message.
#
function error {
  echo -e "\033[31mERROR: $1\033[0m"
}

#
# Prints a red colored error message and exits with an error code.
#
function fail {
  echo -e "\033[31m$1\033[0m"
  exit -1
}

#
# Prints a green colored message.
#
function success {
  echo -e "\033[32m$1\033[0m"
}

#
# Prints a yellow colored warning message.
#
function warning {
  echo -e "\033[33m$1\033[0m";
}

#
# Checks if this machine has all the necessary tools and configurations to handle, not only KVM virtual machines
# but also the commands these scripts perform.
#
function test_support {
  echo "Testing support for virtualization..."
  test_app 'Hardware virtualization support' 'kvm-ok'
  test_app 'kvm' 'which kvm'
  test_app 'qemu' 'which qemu'
  test_app 'brctl' 'which brctl'
  test_app 'ifconfig' 'which ifconfig'
  test_app 'dnsmasq' 'which dnsmasq'
  test_app 'tuntcl' 'which tunctl'
  test_app 'firehol' 'which firehol'
  test_app 'ufw' 'which ufw'
  test_group "user $USER belongs to kvm group"
}

#
# Tests if an application is available.
# Actually this simply runs the command and checks the return code.
# Arguments:
# 1 - The name of the application
# 2 - The command needed to check if the application is available. Basically a 'which <application>'.
#
function test_app {
  local len=$((50 - ${#1}))
  printf "$1%${len}s[ "
  $2 > /dev/null && printf "\033[32mPASS  \033[0m" || printf "\033[31mFAILED\033[0m"
  echo " ]"
}

#
# Tests if the current user belongs to the KVM group.
# Arguments:
# 1 - The test message
#
function test_group {
  local len=$((50 - ${#1}))
  printf "$1%${len}s[ "
  groups $USER | grep 'kvm' > /dev/null && printf "\033[32mPASS  \033[0m" || printf "\033[31mFAILED\033[0m"
  echo " ]"
}
