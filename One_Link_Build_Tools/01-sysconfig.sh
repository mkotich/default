#!/bin/bash
clear
echo "Would you like to format the second HDD"
echo ""
echo "WARNING:  This will format /dev/sdb!"
echo "WARNING:  ONLY respond yes to this if you know what you're doing."
echo -n "(yes/no)> "
        read yesno
        if [[ "$yesno" = "yes" ]]; then
        #FORMAT /dev/sdb
        echo -e "n\np\n1\n\n\nw" | fdisk /dev/sdb
        fi
echo "Would you like to set up the hostname?"
echo -n "(yes/no)> "
        read yesno
        if [[ "$yesno" = "yes" ]]; then
        #Set the hostname
        echo "What is the HOSTNAME of this system?"
        echo -n "(hostname)> "
        read hostname
        echo "$hostname" > /etc/hostname
        `hostname $hostname`
        echo "System HOSTNAME updated to $hostname"
        echo "Modifying hosts file"
        sed -i "s/OneLinkSRV/$hostname.boyd.local $hostname/g" /etc/hosts
        fi
echo "Would you like to set up the network?"
echo -n "(yes/no)> "
        read yesno
        if [[ "$yesno" = "yes" ]]; then
#Set the IP
        echo "What is the IP of this system?"
        echo -n "(IP Address)> "
        read ip
        echo "What is the NETMASK of this system?"
        echo -n "(Netmask)> "
        read netmask
        echo "What is the GATEWAY of this system?"
        echo -n "(Gateway)> "
        read gateway
#Set the IP
        sed -i "s/iface eth0 inet dhcp/\#iface eth0 inet dhcp/g" /etc/network/interfaces
        sed -i "s/\#iface eth0 inet static/iface eth0 inet static/g" /etc/network/interfaces
        sed -i "s/\#address 10.138.99.6/address $ip/g" /etc/network/interfaces
        sed -i "s/\#netmask 255.255.255.0/netmask $netmask/g" /etc/network/interfaces
        sed -i "s/\#gateway 10.138.99.1/gateway $gateway/g" /etc/network/interfaces
        sed -i "s/\#dns-search onelink.local/dns-search boyd.local boyd.net/g" /etc/network/interfaces
        sed -i "s/\#dns-nameservers 8.8.8.8/dns-nameservers 10.200.241.37 10.200.240.150/g" /etc/network/interfaces
        echo "Networking Stopping..."
        `systemctl stop networking`
        echo "Networking Stopped..."
        echo "Flushing IP Information..."
        `ip addr flush eth0`
        echo "Networking Starting, this will take a moment..."
        `systemctl start networking`
        echo "Networking Started..."
        #echo "System IP updated to $ip"
        ipcheck=`ifconfig | grep "inet addr" | grep -v 255.0.0.0`
        echo "New IP: $ipcheck"
        echo "Is the IP Information listed correctly?"
        echo "If the IP Information is missing or incorrect we will try to restart the networking service."
        echo -n "(yes/no)> "
        read yesno2
                if [[ "$yesno2" = "no" ]]; then
                echo "Restarting Networking..."
                `systemctl restart networking`
                echo "Networking Restarted..."
                        #echo "System IP updated to $ip"
                        ipcheck2=`ifconfig | grep "inet addr" | grep -v 255.0.0.0`
                        echo "New IP: $ipcheck2"
                echo "-If the IP Information does not match, you may want to reboot for new IP settings to catch."
                echo "-In that case, reboot the server and rerun this script skipping to the next step."
                echo "How about now?"
                echo -n "(yes/no)> "
                read yesno3
                        if [[ "$yesno3" = "no" ]]; then
                                exit 1
                        fi
                fi
        fi

echo "Would you like to add this server to the BOYD domain?"
echo -n "(yes/no)> "
        read yesno
        if [[ "$yesno" = "yes" ]]; then
        echo "What is your BOYD domain USERNAME?"
        echo -n "(Boyd Username)> "
        read username

#Joining server to domain...
cd software
chmod +x pbis-open-8.8.0.506.linux.x86_64.deb.sh
./pbis-open-8.8.0.506.linux.x86_64.deb.sh
  /opt/pbis/bin/config UserDomainPrefix "BOYD"
  /opt/pbis/bin/config AssumeDefaultDomain "true"
  /opt/pbis/bin/config HomeDirTemplate "%H/%U"
  /opt/pbis/bin/config RemoteHomeDirTemplate "%H/%U"
  /opt/pbis/bin/config HomeDirUmask "077"
  /opt/pbis/bin/config LoginShellTemplate "/bin/bash"
  /opt/pbis/bin/config Local_HomeDirTemplate "%H/%U"
  /opt/pbis/bin/config Local_HomeDirUmask "077"
/opt/pbis/bin/domainjoin-cli join boyd.local $username
#/opt/pbis/bin/domainjoin-cli boyd.local {your boyd domain username here}
echo "IMPORTANT:  In a moment, pam-auth-update will run.  You will need to check all four boxes on this and select OK."
sleep 10
pam-auth-update --force
#echo "# PAM-AUTH-UPDATE REMOVES THIS LINE, WE'RE ADDING IT BACK." >> /etc/pam.d/common-session
#echo "# THIS FILE IS REQUIRED FOR ONELINK STABILITY."
#echo "session required        pam_limits.so" >> /etc/pam.d/common-session
cd ..

#Setting up sudoers file.
sudochk=`grep -i "One Link" /etc/sudoers | wc -l`
if [[ "sudochk" -ne "0" ]]; then
        echo "One Link Groups exist in /etc/sudoers..."
else
        echo "Adding One Link Groups to /etc/sudoers..."
                echo "" >> /etc/sudoers
                echo "#One Link specification" >> /etc/sudoers
                echo "%domain^admins ALL=(ALL) ALL" >> /etc/sudoers
                echo "%grp_bgc_it_sysops_elevated ALL=(ALL) ALL" >> /etc/sudoers
                echo "%grp_it_security ALL=(ALL) ALL" >> /etc/sudoers
                echo "svc_ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
                echo "svc_cyberarkrec ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
                echo "svc_qualys ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        fi
fi
