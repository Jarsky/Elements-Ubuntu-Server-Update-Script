#!/bin/bash
#########################################################
#                                                       #
#          Elements Linux Server Backup Script          #
#                                                       #
#        Written by Jarsky ||  Updated 13/04/2022       #
#                                                       #
#########################################################
#
#
#
#General variables
hostname=$(hostname)
logfile="/var/log/backup-pi.log"
backup_path="/mnt/backup"
threshold=$(date -d "15 days ago" +%d%m%y)
dependencyCheck=true
enableLogging=true

#Email Settings
#using sendEmail e.g apt install sendemail
#Requires an SMTP Relay...e.g https://restorebin.com/configure-postfix-smtp-relay/

sendEmail="false"
externalUrl="https://app.mydomain.com"
fromEmail='My Email<me@email.com>'
toEmail=me@email.com
smtp_relay="smtp.local.lan"
servername="My Server Name"
backupemailTemplate=emails/backup.eml
emailTemp=emails/backup.tmp

#Console Colors
RED='\e[1;31m'
YEL='\e[0;33m'
GRN='\e[0;92m'
NC='\e[0m'
OK='\e[0;92m\u2714\e[0m'
ERR='\e[1;31m\u274c\e[0m'

export emlhostname=$hostname
export emlFromName=$fromName

# Logging
if [ $enableLogging = "true" ]; then
exec 1>> >(ts '[%Y-%m-%d %H:%M:%S]' >> "$logfile") 2>&1
fi

# Check Dependencies
if [ $dependencyCheck = "true" ]; then
        if [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
                OS=$DISTRIB_ID
                VER=$DISTRIB_RELEASE
        elif [ -f /etc/debian_version ]; then
                OS=Debian
                VER=$(cat /etc/debian_version)
        elif [ -f /etc/redhat-release ]; then
                OS=CentOS
                VER=$(rpm -qa \*-release | grep -Ei "oracle|redhat|centos" | cut -d"-" -f3)
        else
                OS=$(uname -s)
                VER=$(uname -r)
        fi

        if [ $OS = "Ubuntu" ] && [ $(dpkg-query -W -f='${Status}' sendemail 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
                        apt-get -y install sendemail moreutils
                        echo ""
                        echo -e "${GRN}Package has been installed, you can now run ${BASH_SOURCE[0]}${NC}\n"
                        echo ""
                        exit 0

        elif [ $OS = "CentOS" ] && [ yum -q list installed moreutils &>/dev/null && echo "Error" ]; then
                        yum -y install sendemail moreutils
                        echo ""
                        echo -e "${GRN}Package has been installed, you can now run ${BASH_SOURCE[0]}${NC}\n"
                        echo ""
                        exit 0
        fi
fi

check_file="$backup_path/check"
if [ ! -f "$check_file" ]; then
    umount $backup_path && mount $backup_path && echo "Backup path recreated"
        echo "Check file did not exist. "$check_file" has been remounted"
        if [ $sendEmail = "true" ]; then
        sendemail -f "$fromEmail" -t $toEmail -s $smtp_relay -u "[CRITICAL] $servername - Check File failed" -m "Check of the backup path failed.\nEnsure that the backup path is properly mounted"
        fi
else
        echo "The check file "$check_file" already exists"
fi

sleep 5

##BACKUP PATHS##
tar -zcvf /tmp/"docker-containers-$(date '+%d%m%y').tar.gz" /opt/
tar -zcvf /tmp/"pi-home-dir-$(date '+%d%m%y').tar.gz" /home/ubuntu/
##BACKUP PATHS END##

rsync --remove-source-files -avz --include='*.tar.gz' --exclude='*/' --exclude='*' /tmp/ $backup_path/$hostname/

find ${backup_path}/$hostname -maxdepth 1 -type f -print0  | while IFS= read -d '' -r file
do
    if [[ "$(basename "$file")" =~ ^.*[0-9]{5}.tar.gz$ ]]
    then
        [ "$(basename "$file" .tar.gz)" -le "$threshold" ] && rm -v -- "$file"
    fi
done

#Get backup filenames and send email
if [ $sendEmail = "true" ]; then
    export emlbkFiles=`ls -pt $backup_path/$hostname/ | grep -E "*tar.gz" | head -n +3`
        rm -rf $emailTemp
        template=$backupemailTemplate
        tmpfile=$emailTemp
        cat $template | envsubst > $tmpfile
        sendemail -f "$fromEmail" -t $toEmail -s $smtp_relay -u "[INFO] $servername - Backup Completed" -o message-file=$emailTemp
    else
        echo 'Email Notification DISABLED'
fi
