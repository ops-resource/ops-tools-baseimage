#!/bin/sh

# Clean up
apt-get --assume-yes remove dkms
apt-get --assume-yes autoremove
apt-get --assume-yes clean

# Remove temporary files
rm -rf /tmp/*

# Zero out free space
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
