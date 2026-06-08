#!/bin/bash

source /opt/mailserver/mailserver.conf

echo "================================="
echo " Mail Server Validation"
echo "================================="

echo
echo "[1/8] LDAP Status"
systemctl is-active slapd

echo
echo "[2/8] Postfix Status"
systemctl is-active postfix

echo
echo "[3/8] Dovecot Status"
systemctl is-active dovecot

echo
echo "[4/8] Mail Queue"
mailq

echo
echo "[5/8] Postfix Configuration"
postfix check

echo
echo "[6/8] Dovecot Configuration"

if doveconf -n >/dev/null 2>&1
then
echo "Dovecot Config OK"
else
echo "Dovecot Config Error"
fi

echo
echo "[7/8] LMTP Socket"

if [ -S /var/spool/postfix/private/dovecot-lmtp ]
then
echo "LMTP Socket Found"
else
echo "LMTP Socket Missing"
fi

echo
echo "[8/8] Finance Group Alias"

postmap -q finance@$DOMAIN 
hash:/etc/postfix/virtual || true

echo
echo "================================="
echo " Validation Complete"
echo "================================="
