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
echo -e "Semi-automatic MySQL installation"
echo -e ""
echo -e "Contents:"
echo -e "- latest MySQL"
echo -e "- MySQL secure installation"
echo -e ""
echo -e "Instructions:"
echo -e "- texts written in ${GREEN}green${NC} are commands, execute them in second terminal window."
echo -e "- texts written in ${BROWN}green${NC} are settings, update them in second terminal window."
echo -e "- texts written in ${RED}red${NC} are just examples you will replace with your data."
echo -e "----------------------------------------------------------------------${NC}"

# Ask user to install MySQL
while true; do
	read -p "Do you want to install MySQL? (y/n): " yn
	case ${yn} in
		[Yy]* )
			sudo apt-get install mysql-server
			break;;
		[Nn]* )
			exit;;
	esac
done

# MySQL secure installation
echo -e "Secure MySQL:"
echo -e "${GREEN}sudo mysql_secure_installation${NC}"
read -p "Press ENTER to reveal installation answers..."
echo -e "Answer the questions:"
echo -e "${BROWN}> n"
echo -e "> SET YOUR PASSWORD"
echo -e "> RE-TYPE YOUR PASSWORD"
echo -e "> y"
echo -e "> y"
echo -e "> y"
echo -e "> y${NC}"
read -p "Press ENTER to continue..."