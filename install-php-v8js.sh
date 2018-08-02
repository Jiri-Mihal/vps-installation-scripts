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
echo -e "Semi-automatic PHP v8js installation"
echo -e ""
echo -e "Contents:"
echo -e "- latest PHP v8js extension from source"
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

# Install v8js
echo -e "Follow the instruction at:"
echo -e "https://github.com/phpv8/v8js/blob/php7/README.Linux.md"
read -p "${GREY}Press ENTER to add v8js extension to php.ini...${NC}"
echo -e "extension=\"v8js.so\"" | sudo tee -a /etc/php/7.2/fpm/php.in
echo -e "extension=\"v8js.so\"" | sudo tee -a /etc/php/7.2/cli/php.in

# Apply new extension
sudo service php7.2-fpm restart

#Troubleshooting
PHP_MODULES=`php -m`
if ! [[ ${PHP_MODULES} = *"v8js"* ]]; then
	cd /tmp/v8
	sudo cp out.gn/x64.release/lib*.so /usr/lib/
	sudo cp -R include/* /usr/include
	sudo cp out.gn/x64.release/natives_blob.bin /usr/lib
	sudo cp out.gn/x64.release/snapshot_blob.bin /usr/lib
	sudo cd out.gn/x64.release/obj
	sudo ar rcsDT libv8_libplatform.a v8_libplatform/*.o
fi

sudo service php7.2-fpm restart
PHP_MODULES=`php -m`
if ! [[ ${PHP_MODULES} = *"v8js"* ]]; then
	echo -e "Unable to install v8js."
fi