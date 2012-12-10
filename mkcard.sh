#! /bin/bash
# mkcard.sh v0.5
# (c) Copyright 2009 Graeme Gregory <dp@xora.org.uk>
# Licensed under terms of GPLv2
#
# Parts of the procudure base on the work of Denys Dmytriyenko
# http://wiki.omap.com/index.php/MMC_Boot_Format
#
# Extended for 3 partitions by Prasad Golla <golla@ti.com> in April 2011.
# The 'media' partition can be used for storing media clips which can 
# be preserved even if the binaries in the other partitions are erased.
#
# Modified for A639 SD card partitioning for Android in December 2012.

export LC_ALL=C

if [ $# -ne 1 ]; then
    echo "Usage: $0 <drive>"
    exit 1;
fi

DRIVE=$1

# In megabytes
SYSTEM_SIZE=200
DATA_SIZE=200
CACHE_SIZE=64

function format_partition {
    PARTITION=$1
    NAME=$2
    
    echo "Formatting $NAME partition..."
    
    if [ -b ${DRIVE}${PARTITION} ]; then
        DEV=${DRIVE}${PARTITION}
    elif [ -b ${DRIVE}p${PARTITION} ]; then
        DEV=${DRIVE}p${PARTITION}
    else
        echo "Can't find partition number ${PARTITION}"
        return 1
    fi
    
    umount ${DEV}
    mke2fs -L "${NAME}" ${DEV} || return 3;
}

function create_drives {
    dd if=/dev/zero of=$DRIVE bs=1024 count=1024 || return 1;

    SIZE=`fdisk -l $DRIVE | grep Disk | grep bytes | awk '{print $5}'`

    echo DISK SIZE - $SIZE bytes

    CYLINDERS=`echo $SIZE/255/63/512 | bc`
    echo CYLINDERS - $CYLINDERS

    {
    echo ,$SYSTEM_SIZE,,-
    echo ,$DATA_SIZE,,-
    echo ,$CACHE_SIZE,,-
    } | sfdisk -uM -D -H 255 -S 63 -C $CYLINDERS $DRIVE || return 2;

    sleep 1
}

echo "WARNING: This will destroy all the data on the given drive!"
echo -n "Do you want to continue [y/N]? "

read answer

case "$answer" in
y) ;;
*) exit ;;
esac

echo "Repartitioning..."
create_drives || { echo "Error on repartitioning!"; exit 1; }

format_partition 1 system
format_partition 2 userdata
format_partition 3 cache

echo "Done."
