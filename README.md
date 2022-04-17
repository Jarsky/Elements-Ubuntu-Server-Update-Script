# Elements-Ubuntu-Server-Update-Script


These scripts are to automate the backup and update of a headless Ubuntu Server. <br />
Written predominantly to use with my Raspberry Pi's due to being unable to Snapshot them. 

Prerequisites
----------

1. Must have an SMTP relay configured for Email Notifications. 
2. Requires `sendemail` to be installed <code>sudo apt install sendemail</code>
3. Requires `TS` to be installed <code>sudo apt install moreutils</code>


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

Important Notes
------------

* The Backup script you will need to manually configure the paths you want to backup. <br />
The default included paths are
`/opt` for Docker and
`/home/ubuntu` for the default Ubuntu users home

* The Backup script will check if a file named `check` exists at the mounted backup location. This is to ensure that backups are being saved to a properly mounted volume. As this is primarily for the backup of Raspberry Pi's which are common for SDCards to fail suddenly and completely, we need to ensure these backups are being offloaded to a network share. 

* If your backup folder is `/mnt/backup` then the check file should be created at `/mnt/backup/check`.<br>
e.g `touch /mnt/backup/check` then ensure you can see this file on your network share.<br>
If the script cannot find this file (such as if the mount as failed), it will attempt to re-mount and will send a notification (if Email is enabled). 

* The upgrade script supports stopping docker containers (excluding Portainer) before restart. 
