#!/bin/bash

# Colors
GREEN="\033[1;32m"
BROWN="\033[0;33m"
GREY="\033[0;37m"
RED="\033[1;31m"
NC="\033[0m"

# Gather required parameters from user
if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
	echo -e "Aborted. Missing required parameters. Call should be: bash backup-to-ftp.sh ${RED}yourftp.tld user pswd 'sources' destination${NC}"
	exit
fi

# FTP connection settings
FTP_ADDRESS=${1}
FTP_USER=${2}
FTP_PASSWORD=${3}
if [[ -z "$5" ]]; then
	FTP_BACKUP_DIR="/backup/"
else
	FTP_BACKUP_DIR=${5}
fi

# Dirs to back up separated by white space.
# Add dirs you want to backup. The following setting
# backups website files, NGiNX settings and MySQL databases
# eq '/var/lib/mysql/ /srv/web/'
DIRS_TO_BACKUP=${4}

# Backup file path
DATE=`date +%Y_%m_%d`
BACKUP_FILE="/tmp/backup_$DATE.tar.gz"

# Compress dirs before upload
tar czf $BACKUP_FILE -P $DIRS_TO_BACKUP

# Upload compressed dirs to FTP
# 1. It connects to FTP with specified user credentials
# 2. It disables SSL connection (comment this line if you have valid SSL for your FTP)
# 3. It creates 'backup' dir on FTP
# 4. It puts compressed backup file to FTP and deletes it
# 5. It rotates old backups.
lftp <<EOF
open $FTP_ADDRESS
user $FTP_USER $FTP_PASSWORD
set ftp:ssl-allow no
mkdir -f $FTP_BACKUP_DIR
put -E $BACKUP_FILE -o $FTP_BACKUP_DIR
recls -1 --sort=date $FTP_BACKUP_DIR | sed -e 's/^/rm\ \/' | sed -e '1,10d' > /tmp/ftp_backups_to_delete.txt
source /tmp/ftp_backups_to_delete.txt
quit
EOF