#!/bin/sh

echo "Disable udev persistent net rules ..."
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm /lib/udev/rules.d/75-persistent-net-generator.rules
rm -rf /dev/.udev/ /var/lib/dhcp3/*
echo "pre-up sleep 2" >> /etc/network/interfaces

echo "Disable DNS reverse lookup ... "
echo "UseDNS no" >> /etc/ssh/sshd_config

echo "Disable the Network Manager ..."
systemctl stop NetworkManager.service
systemctl disable NetworkManager.service

echo "Enable the firewall, blocking all ports except for port 22 (SSH) ..."
ufw allow ssh
ufw --force enable
