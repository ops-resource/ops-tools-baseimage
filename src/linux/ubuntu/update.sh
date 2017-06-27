#!/bin/sh

# Get the list of updates
apt-get -y update

# Upgrades the existing packages
apt-get -y upgrade

# Update new packages
apt-get -y dist-upgrade

# Install dependencies
apt-get -y install dkms
apt-get -y install nfs-common
apt-get -y install update-notifier-common
