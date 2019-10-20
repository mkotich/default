#!/bin/sh

#######################
#Wordpress Plugin Scan 0.11
#######################
#Matt Kotich
#matt@kotich.com
#######################
#This script will scan the sites directory for wordpress installations and
#compare them to the current version available on wordpress.org/download
#
#It will then run 'wp-cli' plugin status check in order to check the state
#of any plugins installed on the site.  This will require the wp-cli script
#from http://wp-cli.org

dirlist=`ls /usr/sites`
wpcli='/usr/local/bin/wp'
currentversion=`curl -L http://wordpress.org/latest 2>/dev/null | tar xzO wordpress/wp-includes/version.php | grep "wp_version" | grep -o "[0-9.]\+"`

echo "Checking for wp-cli at $wpcli"
if [ ! -f $wpcli ]; then
  echo "WARNING:  Cannot continue"
  echo "          Please download and install wp-cli from https://wp-cli.org"
  exit 0
fi
echo "Found $wpcli script, continuing."
#else
#Scanning sites directory for websites containing a wordpress version.php file.
#If one is found, we'll grab the version number and store it in a variable for reporting.
for domain in $dirlist ; do
version=`find /usr/sites/$domain -name version.php -exec grep -H "wp_version\ =" \{\} \; | sed 's/\/usr\/sites\///' | sed 's/\/wp-includes\/version.php:$wp_version//' | sed s/\'\;// | sed s/\'// | sed 's/\// /' | awk {'print $1" "$NF'}`
domain=`echo $version | awk {'print $1'}`
version=`echo $version | awk {'print $2'}`
if test -n "$version"
then
#This is the wp-cli part to scan for plugin versions.
cd \/usr\/sites\/$domain\/www
echo "#####################################################"
#echo "Now in `pwd`" #for debug
echo "domain: $domain : version: $version / $currentversion"
$wpcli  plugin status --allow-root
fi
done
