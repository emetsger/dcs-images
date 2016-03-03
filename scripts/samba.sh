#!/bin/sh
sudo apt-get -y install samba
(echo vagrant; echo vagrant) | sudo smbpasswd -a vagrant -s
sudo sh -c "echo '[shared]' >> /etc/samba/smb.conf"
sudo sh -c "echo 'path = /shared' >> /etc/samba/smb.conf"
sudo sh -c "echo 'valid users = vagrant' >> /etc/samba/smb.conf"
sudo sh -c "echo 'read only = no' >> /etc/samba/smb.conf"
sudo service smbd restart
