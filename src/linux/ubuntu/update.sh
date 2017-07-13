#!/bin/sh

echo "Getting list of updates via apt ..."
echo "Executing 'apt-get --assume-yes update' ..."
apt-get --assume-yes update

# Pin the following packages because if we don't we bork the Hyper-V drivers
# somehow. This might have to do with: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1664663
echo "Putting packages on hold for upgrade due to Hyper-V host connection issues (cont)"
echo "Potentially related to: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1664663 ..."
apt-mark hold linux-headers-generic
apt-mark hold linux-signed-image-generic
apt-mark hold linux-signed-image-4.4.0-81-generic
apt-mark hold linux-image-4.4.0-81-generic
apt-mark hold linux-signed-generic
apt-mark hold linux-headers-4.4.0-81
apt-mark hold linux-image-extra-4.4.0-81-generic
apt-mark hold linux-headers-4.4.0-81-generic

echo "Upgrading existing packages ..."
echo "Executing: 'apt-get --assume-yes upgrade'"
apt-get --assume-yes upgrade

echo "Update new packages and remove old ones ..."
echo "Executing: 'apt-get --assume-yes dist-upgrade'"
apt-get --assume-yes dist-upgrade

echo "Executing: 'apt-get --assume-yes install nfs-common'"
apt-get --assume-yes install nfs-common

echo "Install the update-notifier so that we can easily check if there are updates ..."
echo "Executing: 'apt-get --assume-yes install update-notifier-common'"
apt-get --assume-yes install update-notifier-common
