#!/usr/bin/env bash

# Spins a debian VM with GitLab service
# Assumes the host is a Fedora 42/43

# local git clone of lab configuration
dir_git=${HOME}/Git/github.com/ezech

# this lab config subdir
dir_lab=${dir_git}/lab

# log file for this script
file_log=${HOME}/lab-spin-gitlab-$(date +%Y%m%d%H%M%S).log

# ssh private key 
file_ansible_key="${HOME}/.ssh/id_ansible"

# push information into a log file and on the screen
function log()
{
  str_date="$(date +%Y.%m.%d-%H:%M:%S)"
  echo "[${str_date}] $*"
  echo "[${str_date}] $*" >> $file_log
}

if [ ! -d "$dir_git" ]
then
  log "Will create git clone directory at $dir_git"
  int_result = $(mkdir -p "$dir_git")
  if [ "0" != "$int_result" ]
  then
    log "Can't create local directory for git clone $dir_git"
    exit 1
  fi
fi

log "Installing required packages for host system"
sudo dnf install \
  git \
  ansible \
  ansible-collection-community-libvirt \
  >> $file_log 2>&1


# if not existing already, create a keypair for ansible
if [ ! -e $file_ansible_key ]
then
  log "Creating ansible key $file_ansible_key"
  int_resultssh-keygen -t ed25519 -f "$file_ansible_key" >> $file_log 2>&1
fi




