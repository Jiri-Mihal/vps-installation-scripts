#!/bin/bash

# Colors
GREEN="\033[1;32m"
BROWN="\033[0;33m"
GREY="\033[0;37m"
RED="\033[1;31m"
NC="\033[0m"

# User info
USER=`whoami`
IPV4=`dig +short myip.opendns.com @resolver1.opendns.com`
IPV6=`/sbin/ifconfig eth0 | awk '/inet6/{print $2;exit;}'`

# Prevent running this script as root
if [ "$USER" = "root" ]; then
	echo -e "YOU CAN'T RUN THIS AS ROOT!"
	exit
fi

clear
echo -e "${GREY}----------------------------------------------------------------------"
echo -e "Semi-automatic send-only mail server installation"
echo -e ""
echo -e "Contents:"
echo -e "- send only mail server using the Postfix (one domain only)"
echo -e "- valid email alias for system accounts"
echo -e "- valid SPF and DKIM"
echo -e "- 10/10 from www.mail-tester.com"
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

# Gather domain that postfix will represent
if [[ -z "$1" ]]; then
	echo -e "Enter the ${RED}yourdomain.tld${NC} that this mail server will represent:"
	read DOMAIN
else
	DOMAIN=${1}
fi

# Tell user about reverse DNS
echo -e "Set reverse DNS on your server."
echo -e "${GREY}Note: It's not necessary but it will improve your SPAM score."
echo -e "Linode users: https://www.linode.com/docs/networking/dns/configure-your-linode-for-reverse-dns/${NC}"
read -p "Press ENTER to continue..."

# Install mailutils
echo -e "Install mailutils:"
echo -e "${GREEN}sudo apt-get install mailutils${NC}"
read -p "Press ENTER to reveal installation answers..."
echo -e "Answer the questions:"
echo -e "${BROWN}> Ok"
echo -e "> Internet site"
echo -e "> ${DOMAIN}${NC}"
read -p "Press ENTER to install DKIM..."

# Install DKIM apps
sudo apt-get install opendkim opendkim-tools

# Configure postfix
echo -e "Open Postfix configuration file:"
echo -e "${GREEN}sudo nano /etc/postfix/main.cf${NC}"
read -p "Press ENTER to continue..."
echo -e "Add or edit the following lines in Postfix configuration file:"
echo -e "${BROWN}mydestination = localhost, localhost.\$mydomain, \$mydomain"
echo -e "myhostname = ${DOMAIN}"
echo -e "inet_interfaces = loopback-only${NC}"
read -p "Press ENTER to continue..."
echo -e "# Custom Postfix configuration" | sudo tee -a /etc/postfix/main.cf
echo -e "sender_canonical_maps = hash:/etc/postfix/canonical" | sudo tee -a /etc/postfix/main.cf
echo -e "smtp_tls_security_level = may" | sudo tee -a /etc/postfix/main.cf
echo -e "smtp_tls_loglevel = 1" | sudo tee -a /etc/postfix/main.cf

# Assign real email addresses to system users
echo -e "Enter email alias for system accounts:"
echo -e "Note: System will send email messages from this email alias."
read SYTEM_EMAIL_ALIAS
echo -e "root	${SYTEM_EMAIL_ALIAS}" | sudo tee -a /etc/postfix/canonical
echo -e "root@${HOSTNAME}	${SYTEM_EMAIL_ALIAS}" | sudo tee -a /etc/postfix/canonical
echo -e "${USER}	${SYTEM_EMAIL_ALIAS}" | sudo tee -a /etc/postfix/canonical
echo -e "${USER}@${HOSTNAME}	${SYTEM_EMAIL_ALIAS}" | sudo tee -a /etc/postfix/canonical
sudo postmap /etc/postfix/canonical

# Install DKIM
# more about it at https://blog.whabash.com/posts/send-outbound-email-postfix-dkim-spf-ubuntu-16-04
sudo apt-get install opendkim opendkim-tools

# Configure DKIM
echo -e "" | sudo tee -a /etc/opendkim.conf
echo -e "# Custom DKIM configuration" | sudo tee -a /etc/opendkim.conf
echo -e "AutoRestart             Yes" | sudo tee -a /etc/opendkim.conf
echo -e "AutoRestartRate         10/1h" | sudo tee -a /etc/opendkim.conf
echo -e "UMask                   002" | sudo tee -a /etc/opendkim.conf
echo -e "Syslog                  yes" | sudo tee -a /etc/opendkim.conf
echo -e "SyslogSuccess           Yes" | sudo tee -a /etc/opendkim.conf
echo -e "LogWhy                  Yes" | sudo tee -a /etc/opendkim.conf
echo -e "" | sudo tee -a /etc/opendkim.conf
echo -e "Canonicalization        relaxed/simple" | sudo tee -a /etc/opendkim.conf
echo -e "" | sudo tee -a /etc/opendkim.conf
echo -e "ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts" | sudo tee -a /etc/opendkim.conf
echo -e "InternalHosts           refile:/etc/opendkim/TrustedHosts" | sudo tee -a /etc/opendkim.conf
echo -e "KeyTable                refile:/etc/opendkim/KeyTable" | sudo tee -a /etc/opendkim.conf
echo -e "SigningTable            refile:/etc/opendkim/SigningTable" | sudo tee -a /etc/opendkim.conf
echo -e "" | sudo tee -a /etc/opendkim.conf
echo -e "Mode                    sv" | sudo tee -a /etc/opendkim.conf
echo -e "PidFile                 /var/run/opendkim/opendkim.pid" | sudo tee -a /etc/opendkim.conf
echo -e "SignatureAlgorithm      rsa-sha256" | sudo tee -a /etc/opendkim.conf
echo -e "" | sudo tee -a /etc/opendkim.conf
echo -e "UserID                  opendkim:opendkim" | sudo tee -a /etc/opendkim.conf
echo -e "" | sudo tee -a /etc/opendkim.conf
echo -e "Socket                  inet:12301@localhost" | sudo tee -a /etc/opendkim.conf

echo -e "milter_protocol=2" | sudo tee -a /etc/postfix/main.cf
echo -e "milter_default_action=accept" | sudo tee -a /etc/postfix/main.cf
echo -e "smtpd_milters=inet:localhost:12301" | sudo tee -a /etc/postfix/main.cf
echo -e "non_smtpd_milters=inet:localhost:12301" | sudo tee -a /etc/postfix/main.cf

echo -e "Open DKIM configuration:"
echo -e "${GREEN}sudo nano /etc/default/opendkim${NC}"
read -p "Press ENTER to continue..."

echo -e "Update the following line to:"
echo -e "${BROWN}SOCKET="inet:12301@localhost"${NC}"
read -p "Press ENTER to continue..."

sudo mkdir /etc/opendkim && sudo mkdir /etc/opendkim/keys

echo -e "127.0.0.1" | sudo tee -a /etc/opendkim/TrustedHosts
echo -e "localhost" | sudo tee -a /etc/opendkim/TrustedHosts
echo -e "192.168.0.1/24" | sudo tee -a /etc/opendkim/TrustedHosts
echo -e "" | sudo tee -a /etc/opendkim/TrustedHosts

#DOMAINS_LIST=`echo ${DOMAINS} | tr "," "\n" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
BASE_DIR="/etc/opendkim/keys/"
DKIM_DNS=()
#for DOMAIN in ${DOMAINS_LIST}
#do
    echo -e "*.${DOMAIN}" | tr "," "\n" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sudo tee -a /etc/opendkim/TrustedHosts
    echo -e "mail._domainkey.${DOMAIN} ${DOMAIN}:mail:/etc/opendkim/keys/${DOMAIN}/mail.private" | sudo tee -a /etc/opendkim/KeyTable
    echo -e "*@${DOMAIN} mail._domainkey.${DOMAIN}" | sudo tee -a /etc/opendkim/SigningTable

    FINAL_DIR="${BASE_DIR}${DOMAIN}"
    sudo mkdir ${FINAL_DIR}
    sudo opendkim-genkey --bits 1024 --selector mail --domain ${DOMAIN} --directory ${FINAL_DIR}

    MAIL_PRIVATE_FILE_PATH="${FINAL_DIR}/mail.private"
    sudo chown opendkim:opendkim ${MAIL_PRIVATE_FILE_PATH}

    MAIL_TXT_FILE_PATH="${FINAL_DIR}/mail.txt"
    DKIM=`sudo cat ${MAIL_TXT_FILE_PATH} | awk '/p=/{print $1}' | sed -e 's/^\"*//' -e 's/\"*$//'`
    DKIM_DNS+=("v=DKIM1;h=sha256;k=rsa;${DKIM}")
#done

# DNS records
echo -e "Set valid DNS records for SPF and DKIM:"
echo -e "${BROWN}"
echo -e "@   IN TXT v=spf1 include:spf.${DOMAIN} ~all"
echo -e "spf IN TXT v=spf1 ip4:${IPV4} ip6:${IPV6} ~all"
for DKIM_DNS_ROW in "${DKIM_DNS[@]}"
do
echo -e "mail._domainkey IN TXT ${DKIM_DNS_ROW}"
done
echo -e "${GREY}Notice: DNS change may take up to 24 hours.${NC}"
read -p "Press ENTER to continue..."

# Restart sevices to apply new configuration
sudo service postfix restart
sudo service opendkim restart

# SPAM test
while true; do
	read -p "Do you want proceed SPAM test? (y/n): " yn
	case ${yn} in
		[Yy]* )
			while true; do
				read -p "Do you have access to inbox of ${SYTEM_EMAIL_ALIAS}? (y/n): " yn
				case ${yn} in
					[Yy]* )
						echo "This is the body of the email" | mail -s "This is the subject line" check-auth@verifier.port25.com
						echo -e "Check ${SYTEM_EMAIL_ALIAS} inbox to see deliver-ability result."
						read -p "Press ENTER to continue..."
						break;;
					[Nn]* )
						break;;
				esac
			done

			echo -e "Go to www.mail-tester.com and proceed the test."
			read -p "Press ENTER to continue..."
			break;;
		[Nn]* )
			break;;
	esac
done

# Send test message
while true; do
	read -p "Do you want to send test email message? (y/n): " yn
	case ${yn} in
		[Yy]* )
			echo -e "Enter recipient email address:"
			read TEST_EMAIL_ADDR
			echo "This is the body of the email" | mail -s "This is the subject line" ${TEST_EMAIL_ADDR}
			echo -e "${GREY}We have sent you test email to ${TEST_EMAIL_ADDR}.${NC}"
			read -p "Press ENTER to continue..."
			break;;
		[Nn]* )
			break;;
	esac
done

# Check postfix log file
echo -e "Open postfix log file to see if everything is ok:"
echo -e "${GREEN}sudo cat /var/log/mail.log${NC}"
echo -e "Tip: You can delete log file content with ${GREEN}sudo truncate -s 0 /var/log/mail.log${NC}"

# Installation finished
echo -e ""
read -p "Posfix installation finished, press ENTER..."