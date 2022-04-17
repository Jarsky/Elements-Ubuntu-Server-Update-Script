# Elements-Ubuntu-Server-Update-Script


These scripts are to automate the backup and update of a headless Ubuntu Server. <br />
Written predominantly to use with my Raspberry Pi's due to being unable to Snapshot them. 

The backup script you will need to manually configure the paths you want to backup. <br />
The upgrade script supports stopping docker containers (excluding Portainer) before restart. 

Prerequisites
----------

1. Must have an SMTP relay configured for Email Notifications. 
2. Requires `TS` to be installed <code>sudo apt install moreutils</code>



Usage
----------

Clone the repository to a location e.g ~/scripts<br />
Create the appropriate CRON jobs<br />
Make sure to give enough time between backup and update

<code>sudo crontab -e</code>

<blockquote>
#Run Full Backup<br />
30 2 * * WED /path/to/scripts/backup-pi.sh
</blockquote>
<blockquote>
#Update & Reboot Check<br />
0 3 * * WED /path/to/scripts/upgrade-all.sh
</blockquote>



