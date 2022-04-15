# Elements-Ubuntu-Server-Update-Script


These scripts are to automate the backup and update of a headless Ubuntu Server. 
Written predominantly to use with my Raspberry Pi's

Prerequisites
----------

Must have an SMTP relay configured for Email Notifications. 


Usage
----------

Clone the repository to a location e.g ~/scripts<br />
Create the appropriate CRON jobs<br />
Make sure to give enough time between backup and update

<code>sudo crontab -e</code>

#Run Full Backup<br />
30 2 * * WED /home/ubuntu/scripts/backup-pi.sh

#Update & Reboot Check<br />
0 3 * * WED /home/ubuntu/scripts/upgrade-all.sh




