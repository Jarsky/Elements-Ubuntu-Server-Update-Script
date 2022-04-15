#!/bin/bash
#########################################################
#                                                       #
#          Elements Linux Server Auto Updater           #
#                                                       #
#        Written by Jarsky ||  Updated 13/04/2022       #
#                                                       #
#########################################################
#
#
#
#General Settings
rebootUptime=30 #Uptime in Days
hostname=$(hostname)

#Email Settings
#using sendEmail e.g apt install sendemail
#Requires an SMTP Relay...e.g https://restorebin.com/configure-postfix-smtp-relay/

sendEmail="false"
externalUrl="https://app.mydomain.com"
fromEmail='My Email<me@email.com'
toEmail=me@email.com
smtp_relay="relayserver.local.lan"
servername="My Pi Hole Server"
uptimeTemplate=emails/uptimereboot.eml
updateTemplate=emails/updatereboot.eml
norebootTemplate=emails/noreboot.eml
emailTemp=emails/message.tmp

export emlhostname=$hostname
export emlexternalUrl=$externalUrl
export emluptimereq=$rebootUptime

#Logging
logfile="/var/log/upgrade.log"
exec 1>> >(ts '[%Y-%m-%d %H:%M:%S]' >> "$logfile") 2>&1

#Console Colors
TEXT_RESET='\e[0m'
TEXT_YELLOW='\e[0;33m'
TEXT_GREEN='\e[0;92m'
TEXT_RED_B='\e[1;31m'

if [[ $EUID -ne 0 ]]; then
   echo -e $TEXT_RED_B
   echo "You need to run this as root. e.g sudo $0"
   echo -e $TEXT_RESET
   exit 1
fi

echo -e $TEXT_GREEN
echo ' '
echo 'Starting OS Updates...'
echo ' '
echo -e $TEXT_RESET
sleep 5
sudo apt update -y
echo -e $TEXT_YELLOW
echo 'Repository update finished...'
echo -e $TEXT_RESET
sleep 2
echo -e $TEXT_YELLOW
echo 'Starting Distribution & Package Updates...'
echo -e $TEXT_RESET
sleep 1
sudo apt dist-upgrade -y
echo -e $TEXT_YELLOW
echo 'Distribution upgrade finished...'
echo -e $TEXT_RESET
sleep 1
sudo apt upgrade -y
echo -e $TEXT_YELLOW
echo 'Packages upgrade finished...'
echo -e $TEXT_RESET
sleep 1
sudo apt-get autoremove -y
echo -e $TEXT_YELLOW
echo 'Redundant packages removed...'
echo -e $TEXT_RESET
sleep 1
sudo apt-get autoclean -y
echo -e $TEXT_YELLOW
echo 'Local repository cleaned...'
echo -e $TEXT_RESET
sleep 1
echo -e $TEXT_GREEN
echo 'Testing for Reboot...'
echo -e $TEXT_RESET
days () { uptime | awk '/days?/ {print $3; next}; {print 0}'; }
UPTIME_THRESHOLD=$rebootUptime
if [ $(days) -ge $UPTIME_THRESHOLD ]; then
    echo -e $TEXT_RED_B
    echo "Uptime is more than ${UPTIME_THRESHOLD} days, rebooting in 10 seconds..."
    echo -e $TEXT_RESET
        docker stop $(docker ps -a | grep -v "portainer" | awk 'NR>1 {print $1}')
        if [ $sendEmail = "true" ]; then
        rm -rf $emailTemp
        template=$uptimeTemplate
        tmpfile=$emailTemp
        cat $template | envsubst > $tmpfile
        sendemail -f "$fromEmail" -t $toEmail -s $smtp_relay -u "[WARN] $servername - Reboot" -o message-file=$emailTemp
        else
        echo -e $TEXT_RED_B
        echo 'Email Notification DISABLED'
        echo -e $TEXT_RESET
        fi
        sleep 10
        sudo reboot now
elif [ -f /var/run/reboot-required ]; then
    echo -e $TEXT_RED_B
    echo 'Reboot required! Stopping services and rebooting in 10 seconds...'
    echo -e $TEXT_RESET
        docker stop $(docker ps -a | grep -v "portainer" | awk 'NR>1 {print $1}')
        if [ $sendEmail = "true" ]; then
        rm -rf $emailTemp
        template=$updateTemplate
        tmpfile=$emailTemp
        cat $template | envsubst > $tmpfile
        sendemail -f "$fromEmail" -t $toEmail -s $smtp_relay -u "[WARN] $servername - Reboot" -o message-file=$emailTemp
        else
        echo -e $TEXT_RED_B
        echo 'Email Notification DISABLED'
        echo -e $TEXT_RESET
        fi
        sleep 10
        sudo reboot now
else
    echo -e $TEXT_GREEN
    echo 'Update Finished. No Reboot Required.'
    echo -e $TEXT_RESET
        if [ $sendEmail = "true" ]; then
        rm -rf $emailTemp
        template=$norebootTemplate
        tmpfile=$emailTemp
        cat $template | envsubst > $tmpfile
        sendemail -f "$fromEmail" -t $toEmail -s $smtp_relay -u "[INFO] $servername - No Reboot" -o message-file=$emailTemp
        else
        echo -e $TEXT_RED_B
        echo 'Email Notification DISABLED'
        echo -e $TEXT_RESET
        fi
fi
