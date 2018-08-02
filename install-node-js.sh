#!/bin/bash

# Colors
GREEN="\033[1;32m"
BROWN="\033[0;33m"
GREY="\033[0;37m"
RED="\033[1;31m"
NC="\033[0m"

# User info
USER=`whoami`

# Prevent running this script as root
if [ "$USER" = "root" ]; then
	echo -e "YOU CAN'T RUN THIS AS ROOT!"
	exit
fi

# Ask user to install Node.js and NPM
while true; do
	read -p "Do you want to install Node.js? (y/n): " yn
	case ${yn} in
		[Yy]* )
			sudo apt-get install build-essential
			curl -sL https://deb.nodesource.com/setup_10.x -o ~/nodesource_setup.sh
			sudo bash ~/nodesource_setup.sh
			sudo apt install nodejs
			nodejs -v
			npm -v
			rm ~/nodesource_setup.sh
			break;;
		[Nn]* )
			exit;;
	esac
done

# Ask user to install Node process manager
while true; do
	read -p "Do you want to PM2 process manager? (y/n): " yn
	case ${yn} in
		[Yy]* )
			sudo npm install -g pm2
			break;;
		[Nn]* )
			break;;
	esac
done