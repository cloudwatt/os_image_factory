#!/bin/bash

VOL="/dev/vdb"
VOL_FS_TYPE="ext4"
VOL_MNT_POINT="/mnt/vdb"

echo "  + Stopping duplicity to work"
service duplicity stop

sleep 5

echo -n "  + Waiting for volume to attach."
for i in {1..50}; do
  test -b "$VOL" && break || sleep 5
  if [ "$i" == "50" ]; then
    echo "."
    echo "    + Volume attachment not found : exiting"
    exit 1
  else
    echo -n "."
  fi
done
echo "."
echo "    + Volume attachment was found"

if [ ! -d "$VOL_MNT_POINT" ]; then
  echo "  + Mount point absent : creating $VOL_MNT_POINT"
  mkdir $VOL_MNT_POINT
fi

VOL_MNT="$(mount | grep $VOL)"
if [ -z "$VOL_MNT" ]; then
  echo "  + Volume not mounted : mounting $VOL on $VOL_MNT_POINT"
  mount -t $VOL_FS_TYPE $VOL $VOL_MNT_POINT

  if [ "0" -ne "$?" ]; then
    echo "    + Mount failed : checking filesystem"
    VOL_FS_OK="$(blkid | grep $VOL | grep $VOL_FS_TYPE)"
    if [ -z "$VOL_FS_OK" ]; then
      echo "    + Expected filesystem absent: attempting mkfs + mount"
      mkfs -t ext4 $VOL
      if [ "0" -ne "$?" ]; then
        echo "    + mkfs failed : exiting"
        exit 1
      fi

      mount $VOL $VOL_MNT_POINT
      if [ "0" -ne "$?" ]; then
        echo "    + mkfs succeeded but mount failed: exiting"
        exit 1
      fi
    else
      echo "    + Expected filesystem present but mount failed: exiting. Call a human to debug."
      exit 1
    fi
  fi
fi

  cp -p /etc/stack_public_entry_point $VOL_MNT_POINT/stack_public_entry_point

