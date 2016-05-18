#!/bin/ash

/usr/sbin/smbd -D &
/usr/sbin/nmbd -D &
sleep 5
tail -f /var/log/samba/log.smbd
