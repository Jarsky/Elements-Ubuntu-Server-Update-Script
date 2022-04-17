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

export emlhostname=$hostname
export emlFromName=$fromName

exec 1>> >(ts '[%Y-%m-%d %H:%M:%S]' >> "$logfile") 2>&1

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

tar -zcvf /tmp/"primary-docker-containers-$(date '+%d%m%y').tar.gz" /opt/
tar -zcvf /tmp/"primary-pi-home-dir-$(date '+%d%m%y').tar.gz" /home/ubuntu/

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
