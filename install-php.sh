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

clear
echo -e "${GREY}----------------------------------------------------------------------"
echo -e "Semi-automatic PHP installation"
echo -e ""
echo -e "Contents:"
echo -e "- PHP 7.2"
echo -e "- Proper configuration of PHP and PHP-FPM"
echo -e "- Composer"
echo -e ""
echo -e "Instructions:"
echo -e "- texts written in ${GREEN}green${NC} are commands, execute them in second terminal window."
echo -e "- texts written in ${BROWN}green${NC} are settings, update them in second terminal window."
echo -e "- texts written in ${RED}red${NC} are just examples you will replace with your data."
echo -e "----------------------------------------------------------------------${NC}"

# Ask user to start the installation
while true; do
	read -p "Do you want to start the installation? (y/n): " yn
	case ${yn} in
		[Yy]* )
			sudo apt-get install php7.2-fpm
			break;;
		[Nn]* )
			exit;;
	esac
done

# Ask user for average memory usage per request in MB?
echo -e "What is average memory usage per request in MB (rounded to whole number)?:"
echo -e "${GREY}Notice: It's very important value. This value is base for PHP-FPM pm.max_children value."
echo -e "If pm.max_children is set too low, your server can be very slow with more active users."
echo -e "If pm.max_children is set too high, your server can go down due to insufficient RAM."
echo -e "Use 'echo memory_get_peak_usage() / 1000000;' in your index.php to get average memory usage per request.${NC}"
read USER_MEMORY

# Configure PHP-FPM
AVAILABLE_MEMORY=`free -m | awk '/Mem/{print $7}'`
MAX_CHILDREN=$(( AVAILABLE_MEMORY/USER_MEMORY ))
echo -e "Update PHP-FPM configuration:"
echo -e "${GREEN}sudo nano /etc/php/7.2/fpm/pool.d/www.conf${NC}"
read -p "${GREY}Press ENTER to continue...${NC}"
echo -e "Update the following lines:"
echo -e "${BROWN}pm = ondemand"
echo -e "pm.max_children = ${MAX_CHILDREN}"
read -p "${GREY}Press ENTER to continue...${NC}"

# Configure PHP
echo -e "Update PHP configuration:"
echo -e "${GREEN}sudo nano /etc/php/7.2/fpm/php.ini${NC}"
read -p "${GREY}Press ENTER to continue...${NC}"
echo -e "Update the following lines according to needs of your app:"
echo -e "${BROWN}pm = ondemand"
echo -e "memory_limit = 64M"
echo -e "post_max_size = 2K"
echo -e "upload_max_filesize = 2M"
echo -e "max_file_uploads = 20"
echo -e "allow_url_fopen = Off"
echo -e "file_uploads = Off"
echo -e "max_execution_time = 30"
echo -e "expose_php = Off"
echo -e "disable_functions ="
read -p "${GREY}Press ENTER to continue...${NC}"

# Apply new settings
sudo service php7.2-fpm restart

# Ask user to install Composer
while true; do
	read -p "Do you want to install Composer? (y/n): " yn
	case ${yn} in
		[Yy]* )
			sudo apt-get install curl unzip
			curl -sS https://getcomposer.org/installer -o ~/composer-setup.php
			sudo php ~/composer-setup.php --install-dir=/usr/local/bin --filename=composer
			rm ~/composer-setup.php
			break;;
		[Nn]* )
			break;;
	esac
done