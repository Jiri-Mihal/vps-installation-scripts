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
echo -e "Semi-automatic Webiik or Webiik FW app installation on Nginx"
echo -e ""
echo -e "Contents:"
# todo: Update contents
echo -e "- Create proper folder structure for Nginx"
echo -e "- Clone the git repo of your Webiik FW app"
echo -e "- Set Nginx server configuration file"
echo -e "- Setup logrotate for logs"
echo -e "- Create A grade free SSL certificate"
echo -e "- Install all dependencies"
echo -e "- Create MySQL user with limited privileges, database and tables"
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
			break;;
		[Nn]* )
			exit;;
	esac
done

# Gather required parameters from user
PS3="Do you want to install Webiik or Webiik FW app? : "
select APP_TYPE in Webiik WebiikFW
do
    echo -e "Installing ${APP_TYPE} app..."
    break;
done

echo -e "Enter the domain eq ${RED}yourdomain.tld${NC} associated with this app:"
read DOMAIN
if [[ -z "${DOMAIN}" || "$DOMAIN" = "" ]]; then
	echo -e "Aborted. Domain is required."
	exit
fi
echo -e "Enter the sub-domain eq ${RED}www${NC} associated with this app:"
read SUBDOMAIN
if [[ -z "${SUBDOMAIN}" || "$SUBDOMAIN" = "" ]]; then
	SUBDOMAIN="www"
fi
echo -e "Enter git repo URL of this app:"
read GIT
if [[ -z "${GIT}" || "$GIT" = "" ]]; then
	echo -e "Aborted. Git repo URL is required."
	exit
fi

# Create basic server web dir
if [ ! -d "/srv/web" ]; then
	sudo mkdir /srv/web
	sudo chown root:www-data /srv/web/
	sudo chmod 2775 /srv/web/
fi

# Create app dirs
if [ ! -d "/srv/web/${DOMAIN}/${SUBDOMAIN}" ]; then
	mkdir -p /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs
	mkdir -p /srv/web/${DOMAIN}/${SUBDOMAIN}/ssl
	mkdir -p /srv/web/${DOMAIN}/${SUBDOMAIN}/logs
fi

# Clone/update app from Git
if [ ! -d "/srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private" ]; then
	(cd /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/ && git clone ${GIT} .)
	INSTALL="first"
else
	(cd /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/ && git pull)
	INSTALL="update"
fi

# Add local configuration of app?
if [[ ${INSTALL} = "first" ]]; then
	while true; do
		read -p "Do you want to add and edit config.local.php file? (y/n): " yn
		case ${yn} in
			[Yy]* )
				cp /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private/app/config/config.php /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private/app/config/config.local.php
				nano /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private/app/config/config.local.php
				break;;
			[Nn]* )
				break;;
		esac
	done
fi

# Install required apps for every Webiik FW app
if ! hash php 2>/dev/null; then
	bash ~/install-php.sh
fi
if [ ${APP_TYPE} = "WebiikFW" ]; then
	if ! hash mysql 2>/dev/null; then
		bash ~/install-php-mysql.sh
		bash ~/install-mysql.sh
	fi
fi

if [ ${INSTALL} = "first" ]; then

	# First installation...

	# Launch app installation script
	bash /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private/server/install.sh ${SUBDOMAIN} ${DOMAIN}

	# Install PHP dependencies
	composer install -d /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private

	# Install certbot if it's necessary
	if ! hash certbot 2>/dev/null; then
		sudo add-apt-repository ppa:certbot/certbot
		sudo apt update && sudo apt upgrade
		sudo apt install python-certbot-nginx
	fi

	# Install Let's Encrypt free SSL certificate
	sudo certbot --nginx certonly -d ${DOMAIN}
	sudo certbot --nginx certonly -d ${SUBDOMAIN}.${DOMAIN}
	read -p "Press ENTER to continue..."

	# Test renewal of certificate
	sudo certbot renew --dry-run
	read -p "Press ENTER to continue..."

	# Create Diffie Hellman key
	sudo rm ~/.rnd
	openssl dhparam -out /srv/web/${DOMAIN}/${SUBDOMAIN}/ssl/hellman.pem 2048
	read -p "Press ENTER to continue..."

	# Logrotate
	echo -e "Open logrotate configuration file:"
	echo -e "${GREEN}sudo nano /etc/logrotate.d/nginx${NC}"
	echo -e "Add path ${BROWN}/srv/web/${DOMAIN}/${SUBDOMAIN}/logs/*.log${NC} above path ${BROWN}/var/log/nginx/*.log {}${NC}."
	read -p "Press ENTER to continue..."

	# MySQL user, database, tables
	if [ ${APP_TYPE} = "WebiikFW" ]; then
		echo -e "Log in as root user to MySQL (use password for MySQL root user):"
		sudo mysql -u root -p < /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private/server/db.sql
	fi

	# Update Nginx configuration
	sudo cp /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private/server/${SUBDOMAIN}.*.nginx /etc/nginx/sites-available
	ls /etc/nginx/sites-available

	if [ -f "/srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private/server/nginx-custom-${DOMAIN}.conf" ]; then
		sudo cp /srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private/server/nginx-custom-${DOMAIN}.conf /etc/nginx/custom.conf/
	fi

	# Check Nginx configuration
	sudo nginx -t
	echo -e "If Nginx test above wasn't successful troubleshoot the errors and then run test again:"
	echo -e "${GREEN}sudo nginx -t${NC}"
	read -p "Press ENTER if test results to successful..."

	# Enable app on Nginx
	echo -e "You can enable your app with:"
	echo -e "${GREEN}sudo ln -s /etc/nginx/sites-available/${SUBDOMAIN}.${DOMAIN}.nginx /etc/nginx/sites-enabled${NC}"
	echo -e "${GREEN}sudo nginx -t${NC}"
	echo -e "${GREEN}sudo service nginx restart${NC}"

else

	# Update...

	# Update PHP dependencies
	composer update -d=/srv/web/${DOMAIN}/${SUBDOMAIN}/htdocs/private
fi