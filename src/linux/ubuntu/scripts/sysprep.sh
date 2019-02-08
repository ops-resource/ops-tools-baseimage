#!/bin/bash
#Assign existing hostname to $hostn
hostn=$(cat /etc/hostname)

#Display existing hostname
echo "Existing hostname is $hostn"

#Ask for new hostname $newhost
newhost=${SysprepHostName}

#change hostname in /etc/hosts & /etc/hostname
sudo sed -i "s/$hostn/$newhost/g" /etc/hosts
sudo sed -i "s/$hostn/$newhost/g" /etc/hostname

#display new hostname
echo "Your new hostname is $newhost"