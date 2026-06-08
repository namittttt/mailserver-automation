#!/bin/bash

source /opt/mailserver/mailserver.conf

echo "================================="
echo " LDAP User Creation"
echo "================================="
echo

read -p "Username: " USERNAME
read -p "First Name: " FIRSTNAME
read -p "Last Name: " LASTNAME
read -p "UID Number: " UIDNUMBER
read -s -p "Password: " PASSWORD
echo

EMAIL="${USERNAME}@${DOMAIN}"

EXISTING=$(ldapsearch 
-x 
-LLL 
-b "ou=finance,$BASEDN" 
"(uid=$USERNAME)" dn)

if [ -n "$EXISTING" ]; then
echo
echo "User already exists."
exit 1
fi

HASHED_PASSWORD=$(slappasswd -s "$PASSWORD")

LDIF_FILE="/tmp/${USERNAME}.ldif"

cat > "$LDIF_FILE" <<EOF
dn: uid=$USERNAME,ou=finance,$BASEDN
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount

cn: $FIRSTNAME $LASTNAME
sn: $LASTNAME

uid: $USERNAME

mail: $EMAIL

uidNumber: $UIDNUMBER
gidNumber: $UIDNUMBER

homeDirectory: /home/$USERNAME

loginShell: /bin/bash

userPassword: $HASHED_PASSWORD
EOF

echo
echo "Generated LDIF:"
echo "---------------"
cat "$LDIF_FILE"

echo
read -p "Create LDAP user? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
echo "Cancelled"
exit 0
fi

ldapadd 
-x 
-D "$ADMINDN" 
-w "$LDAPPASS" 
-f "$LDIF_FILE"

mkdir -p /home/$USERNAME/Maildir/{cur,new,tmp}

chown -R "$UIDNUMBER:$UIDNUMBER" 
/home/$USERNAME

echo
echo "Verifying User..."

ldapsearch 
-x 
-LLL 
-b "ou=finance,$BASEDN" 
"(uid=$USERNAME)" uid mail

echo
echo "LDAP User Created"
echo "Maildir Created"
echo "Email Address: $EMAIL"
