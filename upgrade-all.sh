#!/bin/bash
#########################################################
#                                                       #
#          Elements Linux Server Auto Updater           #
#                                                       #
#        Written by Jarsky ||  Updated 23/04/2022       #
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
fromName="Notification"
toEmail=me@email.com
smtp_relay="smtp.local.lan"
servername="My Pi Hole Server"
uptimeTemplate=emails/uptimereboot.eml
updateTemplate=emails/updatereboot.eml
norebootTemplate=emails/noreboot.eml
emailTemp=emails/message.tmp
logfile="/var/log/upgrade.log"
dependencyCheck=true
stopDocker=true

export emlhostname=$hostname
export emlexternalUrl=$externalUrl
export emluptimereq=$rebootUptime
export emlFromName=$fromName

#Console Colors
RED='\e[1;31m'
YEL='\e[0;33m'
GRN='\e[0;92m'
NC='\e[0m'
OK='\e[0;92m\u2714\e[0m'
ERR='\e[1;31m\u274c\e[0m'

# Check running as root
if [[ $EUID -ne 0 ]]; then
   echo ""
   echo -e "[${ERR}]You need to run this as root. e.g sudo $0"
   echo -e "[${OK}]All output will be redirected to $logfile"
   echo ""
   exit 1
fi

#Logging
exec 1>> >(ts '[%Y-%m-%d %H:%M:%S]' >> "$logfile") 2>&1

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

        elif [ $OS = "CentOS" ] && [ yum -q list installed sendemail &>/dev/null && echo "Error" ]; then
                        yum -y install sendemail moreutils
                        echo ""
                        echo -e "${GRN}Package has been installed, you can now run ${BASH_SOURCE[0]}${NC}\n"
                        echo ""
                        exit 0
        fi
fi

echo ' '
echo -e "${GRN}Starting OS Updates...${NC}"
echo ' '
sleep 5
sudo apt update -y
echo -e "${YEL}Repository update finished...${NC}"
sleep 2
echo -e "${YEL}Starting Distribution & Package Updates...${NC}"
sleep 1
sudo apt dist-upgrade -y
echo -e "${YEL}Distribution upgrade finished...${NC}"
sleep 1
sudo apt upgrade -y
echo -e "${YEL}Packages upgrade finished...${NC}"
sleep 1
sudo apt-get autoremove -y
echo -e "${YEL}Redundant packages removed...${NC}"
sleep 1
sudo apt-get autoclean -y
echo -e "${YEL}Local repository cleaned...${NC}"
sleep 1
echo -e "${GRN}Testing for Reboot...${NC}"

days () { uptime | awk '/days?/ {print $3; next}; {print 0}'; }
UPTIME_THRESHOLD=$rebootUptime
if [ $(days) -ge $UPTIME_THRESHOLD ]; then
    echo -e "${RED}Uptime is more than ${UPTIME_THRESHOLD} days, rebooting in 10 seconds...${NC}"
        if [ $stopDocker = "true" ]; then
                docker stop $(docker ps -a | grep -v "portainer" | awk 'NR>1 {print $1}') fi
        if [ $sendEmail = "true" ]; then
                rm -rf $emailTemp
                template=$uptimeTemplate
                tmpfile=$emailTemp
                cat $template | envsubst > $tmpfile
        sendemail -f "$fromEmail" -t $toEmail -s $smtp_relay -u "[WARN] $servername - Reboot" -o message-file=$emailTemp
                else
                echo -e "${RED}Email Notification DISABLED${NC}"
        fi
        sleep 10
        reboot now
elif [ -f /var/run/reboot-required ]; then
    echo -e "${RED}Reboot required! Stopping services and rebooting in 10 seconds...${NC}"
        if [ $stopDocker = "true" ]; then
                docker stop $(docker ps -a | grep -v "portainer" | awk 'NR>1 {print $1}') fi
        if [ $sendEmail = "true" ]; then
                rm -rf $emailTemp
                template=$updateTemplate
                tmpfile=$emailTemp
                cat $template | envsubst > $tmpfile
                sendemail -f "$fromEmail" -t $toEmail -s $smtp_relay -u "[WARN] $servername - Reboot" -o message-file=$emailTemp
        else
                echo -d "${RED}Email Notification DISABLED${NC}"
        fi
        sleep 10
        reboot now
else
    echo -e "${GRN}Update Finished. No Reboot Required.${NC}"
        if [ $sendEmail = "true" ]; then
                rm -rf $emailTemp
                template=$norebootTemplate
                tmpfile=$emailTemp
                cat $template | envsubst > $tmpfile
                sendemail -f "$fromEmail" -t $toEmail -s $smtp_relay -u "[INFO] $servername - No Reboot" -o message-file=$emailTemp
        else
                echo "${RED}Email Notification DISABLED${NC}"
        fi
fi
