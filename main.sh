#!/bin/bash

while true
do
clear

```
echo "======================================="
echo "     MAIL SERVER AUTOMATION SUITE"
echo "======================================="
echo
echo "1. Install Packages"
echo "2. Configure Mail Server"
echo "3. Manage Users"
echo "4. Validate Server"
echo "5. Create LDAP User"
echo "6. Create Mail Group"
echo "7. Test Mail Flow"
echo "8. Exit"
echo

read -p "Enter Choice: " CHOICE

case $CHOICE in

    1)
        sudo ./01-install.sh
        read -p "Press Enter..."
        ;;

    2)
        sudo ./02-configure.sh
        read -p "Press Enter..."
        ;;

    3)
        sudo ./03-manage-users.sh
        read -p "Press Enter..."
        ;;

    4)
        sudo ./04-validate.sh
        read -p "Press Enter..."
        ;;

    5)
        sudo ./05-create-user.sh
        read -p "Press Enter..."
        ;;

    6)
        sudo ./06-create-group.sh
        read -p "Press Enter..."
        ;;

    7)
        sudo ./07-test-mailflow.sh
        read -p "Press Enter..."
        ;;

    8)
        echo "Exiting..."
        exit 0
        ;;

    *)
        echo "Invalid Choice"
        sleep 2
        ;;
esac
```

done
