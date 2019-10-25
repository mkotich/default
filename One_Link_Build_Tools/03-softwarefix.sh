#!/bin/sh

#Fixing Samba
echo "Fixing Samba..."
sed -i 's/map to guest = bad user/map to guest = Never\n   restrict anonymous = 2/g' /etc/samba/smb.conf 
service smbd restart

#Fixing Postfix
echo "Disabling TLS in Postfix..."
sed -i 's/smtpd_use_tls=yes/smtpd_use_tls=no/g' /etc/postfix/main.cf
service postfix restart

#THE FOLLOWING HAS BEEN REMOVED AS THE LATEST ISO IS UP TO DATE
#echo "Removing older versions of Java..."
#dpkg --purge oracle-java8-installer > /dev/null 2>&1
#dpkg --purge oracle-java8-jre > /dev/null 2>&1
#dpkg --purge oracle-java8-set-default > /dev/null 2>&1
#apt autoremove > /dev/null 2>&1
#echo "Installing newer version of Java..."
#dpkg --force-all -i software/oracle-java8-jre_8u211_amd64.deb > /dev/null 2>&1 
#echo "Java version 8u211 installed."
#tar -zxf software/jre-8u221-linux-x64.tar.gz -C /usr/lib/jvm/ > /dev/null 2>&1
#echo "Java update to 8u221 installed."
#echo "IMPORTANT:  In a moment, the java version picker will launch.  To finish this installation you must select 1 in this menu."
#update-alternatives --install /usr/bin/java java /usr/lib/jvm/jre1.8.0_221/bin/java 3
#sleep 10
#update-alternatives --config java
