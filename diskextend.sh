# Linux Disk Extension Script v1.01
# Matt Kotich - 7/19/2022
# matt@kotich.com
#
# This script will require you to ADD A NEW DRIVE to vCenter.
# This script does not work with EXTENDING an existing drive.
#
# If you need to remove safety prompts for automation, find
# the 'safety' variable and change it from 'on' to 'off'.
#
# This script will perform the following steps on a server:
# 1)  Scan /dev for sdX files (scsi drives) and loop those
#     drives in order to find the first drive that does not
#     have any partitions created on it.
# 2)  Runs sfdisk to create an active partition that utilizes
#     the full disk, and labels it as Linux LVM (8e).
# 3)  Automatically detects all pertinant LVM information
#     (vg name, lv name, lv path, etc).
# 4)  Creates a new Physical Volume for LVM out of the newly
#     created /dev/sd*1 device.
# 5)  Extends the root LVM's Volume Group by adding the newly
#     created /dev/sd*1 Physical Volume.
# 6)  Extends the LVM to use 100% of the available space in the
#     volume.
# 7)  Runs xfs_growfs to add the new space metrics to the xfs
#     filesystem
###############################################################

if [[ `id -u` != 0 ]]; then
	echo "Must be root to run script"
	exit
fi

#################
#SCRIPT VARIABLES
#Do not chang these unless you know what you are doing.
#################
safety="on" #change on to off here to eliminate the safety check further down in this script.
newdev=`for i in \`ls /dev/sd?\`;do fdisk -l $i|echo "$i" \`grep -c "Disk identifier"\`|grep 0|awk '{print $1}';done`
newprt="$newdev"1
newprtsize=`fdisk -l|tail -n5|head -n1|awk '{print $3$4}'|sed -e s/,//`
dfinfo=`df /|tail -n1|awk '{print $1}'`
rootvg=`lvdisplay $dfinfo | grep "VG Name"|awk '{print $NF}'`
rootlv=`lvdisplay $dfinfo | grep "LV Name"|awk '{print $NF}'`
lvpath=`lvdisplay $dfinfo | grep "LV Path"|awk '{print $NF}'`

#Checking for new device on the system.
#if newdev could not find a new /dev/sdX this part will fail.
if [[ $newdev == "/dev/sd"* ]]
	then
		echo "New device has been found, continuing."
else
		echo "No new device exists on this system."
		echo "Please add a new drive to this system in vCenter and run this script again."
		echo "Please note, a new drive must be ADDED, an existing drive cannot be EXTENDED."
		exit 0
fi

#still trying to figure out how to nest the safety switch.
#ran out of time for today.  will fix later.
if [[ $safety == "on" ]]
        then

#WARNINGS
echo "Does the below information look correct?"
echo "a) HDD space should be what you're expecting to see"
echo "b) Device name should seem reasonable"
echo ""
echo Current HDD space for / is `df -h /|tail -n1|awk '{print $2}'`, we are attempting to extend it by $newprtsize
echo ""
echo "New Device should look something like /dev/sdX"
echo "New Device is: " $newdev
echo ""

echo -n "If the information above looks correct, type the name of the new device listed above to continue: "
read yesno
if [ -z "$yesno" ]
	then
		echo "Input cannot be blank."
		exit 0
fi
else
        echo "Safety has been disabled, continuing."
        yesno=$newdev
fi
if
 [[ $yesno = $newdev ]]; then
	echo ",,83" |sfdisk -1 $newdev &>/tmp/diskextend.txt
echo "Creating PV for $newprt"
	pvcreate $newprt
echo "Extending Volume Group for /dev/$rootvg by $newprt"
	vgextend /dev/$rootvg $newprt
echo "Extending LV for /dev/$rootvg/$rootlv"
	lvextend -l +100$FREE /dev/$rootvg/$rootlv
#echo "LVchange for /dev/$rootvg/$rootlv"
	lvm lvchange -a y /dev/$rootvg/$rootlv
#echo "Growing /dev/$rootvg/$rootlv with xfs_growfs"
	xfs_growfs -d /dev/$rootvg/$rootlv &>> /tmp/diskextend.txt
	echo ""
	echo "HDD has been extended to" `df -h /|tail -n1|awk '{print $2}'`
else
	echo "Dying, then."
	exit
fi
