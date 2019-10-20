#!/bin/sh

#This script will scan the sites directory for wordpress installations
#and compare them to the current version available on wordpress.org/download

dirlist=`ls /usr/sites`
currentversion=`curl -L http://wordpress.org/latest 2>/dev/null | tar xzO wordpress/wp-includes/version.php | grep "wp_version" | grep -o "[0-9.]\+"`

for domain in $dirlist ; do
version=`find /usr/sites/$domain -name version.php -exec grep -H "wp_version\ =" \{\} \; | sed 's/\/usr\/sites\///' | sed 's/\/wp-includes\/version.php:$wp_version//' | sed s/\'\;// | sed s/\'// | sed 's/\// /' | awk {'print $1" "$NF'}`
domain=`echo $version | awk {'print $1'}`
version=`echo $version | awk {'print $2'}`
if test -n "$version"
then
echo "domain: $domain : version: $version / $currentversion" 
fi
done
#echo "To: matt@kotich.com" >/tmp/wprept.txt
#echo "From: root@kotich.com" >>/tmp/wprept.txt
#echo "Subject: Weekly Wordpress Update" >>/tmp/wprept.txt
#cat /tmp/wpscan.txt >> /tmp/wprept.txt
#sendmail -t < /tmp/wprept.txt
#rm /tmp/wpscan.txt
#rm /tmp/wprept.txt
#here's a command line argument to run from /sites to scan manually.
#sometimes scanning by hand turns up more than this script as the script only returns
#one match per domain.  Some domains have been found to have more than 1 installation
#for some reason...
#find /usr/sites -name version.php -exec grep -H "wp_version\ =" \{\} \; | sed 's/\/usr\/sites\///' | sed 's/\/wp-includes\/version.php:$wp_version//' | sed s/\'\;// | sed s/\'//