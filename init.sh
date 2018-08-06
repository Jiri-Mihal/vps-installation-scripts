#!/bin/bash

# Actualize system
while true; do
	read -p "Do you want to update system? (y/n): " yn
	case ${yn} in
		[Yy]* )
			apt-get update && apt-get upgrade
			break;;
		[Nn]* )
			break;;
	esac
done

# Download installation scripts
mkdir ~/vps-installation-scripts
cd ~/vps-installation-scripts
curl -LOk https://github.com/Jiri-Mihal/vps-installation-scripts/archive/master.zip
unzip master.zip
cd vps-installation-scripts-master
mv *.sh ~/
cd ~
rm -r ~/vps-installation-scripts

# Ask for time-zone change
while true; do
	read -p "Do you want to change time zone? [America/Phoenix] (y/n): " yn
	case $yn in
		[Yy]* )
		sudo dpkg-reconfigure tzdata
		break;;
		[Nn]* )
		break;;
	esac
done