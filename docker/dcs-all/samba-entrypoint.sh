#!/bin/ash

if [ ! -f ${SHARED}/etc/samba/smb.conf ] ; then
  echo "Creating ${SHARED}/etc/samba/smb.conf from ${SHARED}/etc/samba/smb.conf.tmpl"
  cat ${SHARED}/etc/samba/smb.conf.tmpl | envsubst > ${SHARED}/etc/samba/smb.conf
fi

/usr/sbin/smbd -D -s ${SHARED}/etc/samba/smb.conf &
/usr/sbin/nmbd -D -s ${SHARED}/etc/samba/smb.conf &

sleep 5

tail -f /var/log/samba/log.smbd
