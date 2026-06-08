#!/bin/bash

source /opt/mailserver/mailserver.conf

echo "================================="
echo " MAIL SERVER HEALTH CHECK"
echo "================================="
echo

echo -n "LDAP Service    : "
systemctl is-active slapd

echo -n "Postfix Service : "
systemctl is-active postfix

echo -n "Dovecot Service : "
systemctl is-active dovecot

echo
echo "Checking LMTP Socket..."

if [ -S /var/spool/postfix/private/dovecot-lmtp ]; then
    echo "✓ LMTP Socket Found"
else
    echo "✗ LMTP Socket Missing"
fi

echo
echo "Checking Mail Queue..."
mailq

echo
echo "Checking Dovecot User Lookup..."

read -p "Enter Username: " USERNAME

doveadm user "$USERNAME"

echo
echo "Checking Group Aliases..."

cat /etc/postfix/virtual

echo
echo "Health Check Completed"
