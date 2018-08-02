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

# Ask user to install APCU
while true; do
	read -p "Do you want to install and setup PHP APCU extension? (y/n): " yn
	case ${yn} in
		[Yy]* )
			sudo apt-get install php-pear
			sudo pecl install apcu
			sudo service php7.2-fpm restart
			break;;
		[Nn]* )
			break;;
	esac
done
