#!/bin/bash

set -e

echo "========================================"
echo " Mail Server Configuration"
echo "========================================"

read -p "Domain Name (example: namit.com): " DOMAIN

MAILHOST="mail.$DOMAIN"

FIRST_PART=$(echo "$DOMAIN" | cut -d'.' -f1)
SECOND_PART=$(echo "$DOMAIN" | cut -d'.' -f2)

CAP_FIRST="$(tr '[:lower:]' '[:upper:]' <<< ${FIRST_PART:0:1})${FIRST_PART:1}"

BASEDN="dc=$CAP_FIRST,dc=$SECOND_PART"

ADMINDN="cn=admin,$BASEDN"

echo
echo "Generate LDAP password automatically? (y/n)"
read AUTO_PASS

if [ "$AUTO_PASS" = "y" ]; then

    if ! command -v pwgen >/dev/null 2>&1
    then
        apt update
        apt install -y pwgen
    fi

    LDAPPASS=$(pwgen 16 1)

    echo
    echo "Generated LDAP Password:"
    echo "$LDAPPASS"

else

    read -s -p "LDAP Password: " LDAPPASS
    echo

fi

echo
echo "Configuration Summary"
echo "---------------------"
echo "Domain      : $DOMAIN"
echo "Hostname    : $MAILHOST"
echo "Base DN     : $BASEDN"
echo "Admin DN    : $ADMINDN"
ORG=$(echo "$DOMAIN" | cut -d'.' -f1)
TLD=$(echo "$DOMAIN" | cut -d'.' -f2)
echo

read -p "Proceed? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Aborted."
    exit 1
fi

mkdir -p /opt/mailserver

cat > /opt/mailserver/mailserver.conf <<EOF
DOMAIN=$DOMAIN
MAILHOST=$MAILHOST
BASEDN=$BASEDN
ADMINDN=$ADMINDN
LDAPPASS=$LDAPPASS
USER_OU=$USER_OU
GROUP_OU=$GROUP_OU
EOF

echo
echo "[1/9] Creating LDAP OUs..."

cat > /tmp/ou.ldif <<EOF

dn: ou=$USER_OU,$BASEDN
objectClass: organizationalUnit
ou: $USER_OU

dn: ou=$GROUP_OU,$BASEDN
objectClass: organizationalUnit
ou: $GROUP_OU

ldapadd -x -D "$ADMINDN" -w "$LDAPPASS" -f /tmp/ou.ldif || true

echo
echo "[2/9] Creating Postfix LDAP Lookup File..."

cat > /etc/postfix/ldap-users.cf <<EOF
server_host = 127.0.0.1

search_base = $BASEDN

query_filter = (mail=%s)

result_attribute = mail

bind = yes

bind_dn = $ADMINDN

bind_pw = $LDAPPASS
EOF

chmod 600 /etc/postfix/ldap-users.cf

echo
echo "[3/9] Configuring Postfix..."

postconf -e "myhostname=$MAILHOST"

postconf -e "mydomain=$DOMAIN"

postconf -e "myorigin=\$mydomain"

postconf -e "virtual_mailbox_domains=$DOMAIN"

postconf -e "virtual_mailbox_maps=ldap:/etc/postfix/ldap-users.cf"

postconf -e "virtual_alias_maps=hash:/etc/postfix/virtual"

postconf -e "virtual_transport=lmtp:unix:private/dovecot-lmtp"

postconf -e "mailbox_transport=lmtp:unix:private/dovecot-lmtp"

postconf -e "smtpd_sasl_type=dovecot"

postconf -e "smtpd_sasl_path=private/auth"

postconf -e "smtpd_sasl_auth_enable=yes"

echo
echo "[4/9] Creating Virtual Alias File..."

touch /etc/postfix/virtual

postmap /etc/postfix/virtual

echo
echo "[5/9] Configuring Dovecot LDAP..."

cat > /etc/dovecot/dovecot-ldap.conf.ext <<EOF
hosts = 127.0.0.1

dn = $ADMINDN
dnpass = $LDAPPASS

ldap_version = 3

base = $BASEDN

pass_filter = (&(objectClass=posixAccount)(mail=%u))

user_filter = (&(objectClass=posixAccount)(mail=%u))

default_pass_scheme = SSHA

user_attrs = \
homeDirectory=home,\
uidNumber=uid,\
gidNumber=gid
EOF

echo
echo "[6/9] Configuring Maildir..."

sed -i '/mail_uid = vmail/d' \
/etc/dovecot/conf.d/10-mail.conf

sed -i '/mail_gid = vmail/d' \
/etc/dovecot/conf.d/10-mail.conf

#grep -q "^mail_location" \
#/etc/dovecot/conf.d/10-mail.conf \
#|| echo "mail_location = maildir:~/Maildir" \
#>> /etc/dovecot/conf.d/10-mail.conf

#grep -q "^first_valid_uid" \
#/etc/dovecot/conf.d/10-mail.conf \
#|| echo "first_valid_uid = 1000" \
#>> /etc/dovecot/conf.d/10-mail.conf

echo
echo "[7/9] Configuring LMTP..."

cat > /etc/dovecot/conf.d/99-lmtp.conf <<EOF
service lmtp {
 unix_listener /var/spool/postfix/private/dovecot-lmtp {
   mode = 0600
   user = postfix
   group = postfix
 }
}
EOF

echo
echo "[8/9] Configuring Roundcube..."

if [ -f /etc/roundcube/config.inc.php ]; then

sed -i \
"s#\$config\['default_host'\].*#\$config['default_host'] = 'localhost';#" \
/etc/roundcube/config.inc.php || true

sed -i \
"s#\$config\['smtp_host'\].*#\$config['smtp_host'] = 'localhost';#" \
/etc/roundcube/config.inc.php || true

fi

echo
echo "[9/9] Restarting Services..."

systemctl restart postfix
systemctl restart dovecot

echo
echo "========================================"
echo " Configuration Complete"
echo "========================================"

echo
echo "Saved Configuration:"
echo "/opt/mailserver/mailserver.conf"

echo
echo "Domain     : $DOMAIN"
echo "Hostname   : $MAILHOST"
echo "Base DN    : $BASEDN"
echo "Admin DN   : $ADMINDN"
echo "LDAP Pass  : $LDAPPASS"
