#!/bin/bash

set -e

echo "========================================"
echo " Mail Server Installation"
echo "========================================"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

echo
echo "[1/5] Updating Packages..."
apt update

echo
echo "[2/5] Installing Mail Server Packages..."

DEBIAN_FRONTEND=noninteractive apt install -y \
postfix \
postfix-ldap \
dovecot-core \
dovecot-imapd \
dovecot-pop3d \
dovecot-lmtpd \
dovecot-ldap \
slapd \
ldap-utils \
roundcube \
roundcube-core \
apache2 \
php \
php-cli \
php-common \
php-ldap \
php-mbstring \
php-intl \
php-mysql \
pwgen \
mailutils \
telnet

echo
echo "[3/5] Enabling Services..."

systemctl enable slapd
systemctl enable postfix
systemctl enable dovecot
systemctl enable apache2

echo
echo "[4/5] Starting Services..."

systemctl restart slapd
systemctl restart postfix
systemctl restart dovecot
systemctl restart apache2

echo
echo "[5/5] Installation Verification..."

systemctl is-active slapd
systemctl is-active postfix
systemctl is-active dovecot
systemctl is-active apache2

echo
echo "========================================"
echo " Installation Completed"
echo "========================================"
