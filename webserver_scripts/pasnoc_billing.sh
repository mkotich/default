#/bin/sh

#Version 1.0
##This script will create a status email from maillogs generated from
#Pasnoc's billing email system.
#
##Pasnoc sends billing emails generated by Nancy's computer, which are
#routed through this server.
#
##This script will run every five minutes. (or as scheduled by crontab.)
#
##This script will first check to see if a token has been set by the
#status email being sent.
#
##If no token is found, the script will run.
#
##If the script runs and does not find significant mail has been sent
#from info@pasnoc.net to their customers, the script will exit.
#
##If the script finds more than 90 emails have been sent from
#info@pasnoc.net, it will generate reports and send them to
#info@pasnoc.net.
#
##Once the email is sent, the script will generate a token
#(/tmp/Mar, for example).
#
##If this token exists, the script will exit, thus cancelling any duplicate
#emails

reportmail=nancy@pasnoc.net,matt@kotich.com
repdate=`date +%b`
reptoken=\/tmp\/pasnoc-`date +%b`
maillog=/var/log/maillog
tempfile=pasnoc-messages-sent

#If token exists and is not current month, delete it.
#This is kind of a dirty way to get this done, but it'll work for now.
#If the current "/tmp/pasnoc-Month" file does not equal the current Month.
#The script will delete /tmp/pasnoc-* from the /tmp directory.
#This will clear any existing tokens.  I should rename the tokens to include
#the word token, so we can make sure not to delete anything else if we ever
#add more tokens, but that's for later.

if [ "`ls /tmp | grep pasnoc | sed -e s/pasnoc-//`" != "$repdate" ] ; then
    rm -f /tmp/pasnoc-*
fi

#Check for token file, if exists, exit.
if [[ -f $reptoken ]] ; then
    echo Report for this month has already been sent.
    echo Exiting.
    exit
fi

#Gather postfix message number for all messages from info@pasnoc.net.
for record in `cat $maillog | grep $repdate | grep info\@pasnoc.net | awk '{ print $6 }' | sed -e 's/://'`
do
#Using postfix message number, gather all recipient email addresses and their sent status.
cat $maillog | grep $record | grep to | awk '{ print tolower($7)","$12 }' | sed -e 's/to=<//' | sed -e 's/>,//'>> $tempfile;
#Sort the list of recipients and statuses alphabetically.
sort $tempfile > pasnoc-sorted
done

#Count the number of times each recipient is listed in results.
echo "Address Status Sent">> pasnoc-sorted-counted
for lines in `cat pasnoc-sorted`; do count=`grep -c $lines pasnoc-sorted`; echo $lines $count;done>>pasnoc-sorted-counted
#Eliminates duplicate lines.
linecount=`wc -l < pasnoc-sorted-counted`
echo "Total Emails Sent: $linecount" >> pasnoc-final
echo "(Sorted Alphabetically)" >> pasnoc-final
awk '!a[$0]++' pasnoc-sorted-counted | sed -e 's/\,/ /' | sed -e 's/status=//' | column -t >> pasnoc-final
#This will create a token to say how many emails have been sent to decide whether or not to send an email.
#If there are only a few emails sent, we will not send because the mailing is probably in progress.
cat pasnoc-final | awk {'print $3'} | grep -v Sent | awk 'BEGIN {sum=0} {for(i=1; i<=NF; i++) sum+=$i } END {print sum}' > pasnoc-sendmail-token
#Domain count
tail -n+3 pasnoc-final | sed -e 's/@/ /' | awk {'print $2'} >> pasnoc-domains
for i in `cat $i pasnoc-domains | grep -v Status`; do count=`grep -c $i pasnoc-domains`; echo $i $count; done>>pasnoc-domains-counted
awk '!a[$0]++' pasnoc-domains-counted | sed -e 's/\,/ /' >> pasnoc-domains-final
sort -k2 -r pasnoc-domains-final | column -t >>pasnoc-domains-final-sorted
echo ================
echo Delivery Report
echo ================
cat pasnoc-final
echo ========
echo Domains
echo ========
cat pasnoc-domains-final-sorted

#SEND REPORT TO EMAIL
token=`cat pasnoc-sendmail-token`
if [ "$token" -gt "90" ]; then
	echo token is greater than 90, sending email
	cat pasnoc-final > pasnoc-mail-package
	echo "" >> pasnoc-mail-package
	echo "Domains delivered to (sorted by bulk):" >> pasnoc-mail-package
	echo "This shows UNIQUE emails sent to, not total emails sent to a domain." >> pasnoc-mail-package
	echo "If a person gets more than one email (as happens with caremore) they only count once here." >> pasnoc-mail-package
	cat pasnoc-domains-final-sorted >> pasnoc-mail-package
	mail -s 'Billing Email Delivery Report' $reportmail < pasnoc-mail-package
	rm pasnoc-mail-package
	echo Email Sent
	touch $reptoken
else
	echo token is less than 90, waiting to send email
fi
#Clean up after ourselves.
rm -f pasnoc-*