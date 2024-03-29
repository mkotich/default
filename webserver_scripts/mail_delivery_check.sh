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
#from info@$DOMAIN to their customers, the script will exit.
#
##If the script finds more than 90 emails have been sent from
#info@$DOMAIN, it will generate reports and send them to
#info@$DOMAIN.
#
##Once the email is sent, the script will generate a token
#(/tmp/Mar, for example).
#
##If this token exists, the script will exit, thus cancelling any duplicate
#emails

DOMAIN=yourdomain.com
reportmail=your@email.com
repdate=`date +%b`
reptoken=\/tmp\/email-delivery-report-`date +%b`
maillog=/var/log/maillog
tempfile=email-delivery-report-messages-sent

#If token exists and is not current month, delete it.
#This is kind of a dirty way to get this done, but it'll work for now.
#If the current "/tmp/email-delivery-report-Month" file does not equal the current Month.
#The script will delete /tmp/email-delivery-report-* from the /tmp directory.
#This will clear any existing tokens.  I should rename the tokens to include
#the word token, so we can make sure not to delete anything else if we ever
#add more tokens, but that's for later.

if [ "`ls /tmp | grep pasnoc | sed -e s/email-delivery-report-//`" != "$repdate" ] ; then
    rm -f /tmp/email-delivery-report-*
fi

#Check for token file, if exists, exit.
if [[ -f $reptoken ]] ; then
    echo Report for this month has already been sent.
    echo Exiting.
    exit
fi

#Gather postfix message number for all messages from info@$DOMAIN.
for record in `cat $maillog | grep $repdate | grep info\@$DOMAIN | awk '{ print $6 }' | sed -e 's/://'`
do
#Using postfix message number, gather all recipient email addresses and their sent status.
cat $maillog | grep $record | grep to | awk '{ print tolower($7)","$12 }' | sed -e 's/to=<//' | sed -e 's/>,//'>> $tempfile;
#Sort the list of recipients and statuses alphabetically.
sort $tempfile > email-delivery-report-sorted
done

#Count the number of times each recipient is listed in results.
echo "Address Status Sent">> email-delivery-report-sorted-counted
for lines in `cat email-delivery-report-sorted`; do count=`grep -c $lines email-delivery-report-sorted`; echo $lines $count;done>>email-delivery-report-sorted-counted
#Eliminates duplicate lines.
linecount=`wc -l < email-delivery-report-sorted-counted`
echo "Total Emails Sent: $linecount" >> email-delivery-report-final
echo "(Sorted Alphabetically)" >> email-delivery-report-final
awk '!a[$0]++' email-delivery-report-sorted-counted | sed -e 's/\,/ /' | sed -e 's/status=//' | column -t >> email-delivery-report-final
#This will create a token to say how many emails have been sent to decide whether or not to send an email.
#If there are only a few emails sent, we will not send because the mailing is probably in progress.
cat email-delivery-report-final | awk {'print $3'} | grep -v Sent | awk 'BEGIN {sum=0} {for(i=1; i<=NF; i++) sum+=$i } END {print sum}' > email-delivery-report-sendmail-token
#Domain count
tail -n+3 email-delivery-report-final | sed -e 's/@/ /' | awk {'print $2'} >> email-delivery-report-domains
for i in `cat $i email-delivery-report-domains | grep -v Status`; do count=`grep -c $i email-delivery-report-domains`; echo $i $count; done>>email-delivery-report-domains-counted
awk '!a[$0]++' email-delivery-report-domains-counted | sed -e 's/\,/ /' >> email-delivery-report-domains-final
sort -k2 -r email-delivery-report-domains-final | column -t >>email-delivery-report-domains-final-sorted
echo ================
echo Delivery Report
echo ================
cat email-delivery-report-final
echo ========
echo Domains
echo ========
cat email-delivery-report-domains-final-sorted

#SEND REPORT TO EMAIL
token=`cat email-delivery-report-sendmail-token`
if [ "$token" -gt "90" ]; then
	echo token is greater than 90, sending email
	cat email-delivery-report-final > email-delivery-report-mail-package
	echo "" >> email-delivery-report-mail-package
	echo "Domains delivered to (sorted by bulk):" >> email-delivery-report-mail-package
	echo "This shows UNIQUE emails sent to, not total emails sent to a domain." >> email-delivery-report-mail-package
	echo "If a person gets more than one email (as happens with caremore) they only count once here." >> email-delivery-report-mail-package
	cat email-delivery-report-domains-final-sorted >> email-delivery-report-mail-package
	mail -s 'Billing Email Delivery Report' $reportmail < email-delivery-report-mail-package
	rm email-delivery-report-mail-package
	echo Email Sent
	touch $reptoken
else
	echo token is less than 90, waiting to send email
fi
#Clean up after ourselves.
rm -f email-delivery-report-*
