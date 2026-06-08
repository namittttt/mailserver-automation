#!/bin/bash

source /opt/mailserver/mailserver.conf

while true
do
clear

```
echo "================================="
echo " Mail Server User Management"
echo "================================="
echo
echo "1. List LDAP Users"
echo "2. List Group Aliases"
echo "3. Search User"
echo "4. Back"
echo

read -p "Enter Choice: " CHOICE

case $CHOICE in

    1)

        ldapsearch \
        -x \
        -LLL \
        -b "ou=finance,$BASEDN" \
        "(objectClass=posixAccount)" \
        uid mail

        echo
        read -p "Press Enter..."
        ;;

    2)

        cat /etc/postfix/virtual

        echo
        read -p "Press Enter..."
        ;;

    3)

        read -p "Username: " USERNAME

        ldapsearch \
        -x \
        -LLL \
        -b "ou=finance,$BASEDN" \
        "(uid=$USERNAME)"

        echo
        read -p "Press Enter..."
        ;;

    4)

        exit 0
        ;;

    *)

        echo "Invalid Choice"
        sleep 2
        ;;

esac
```

done
