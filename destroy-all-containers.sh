#!/bin/bash

echo "killing containers"
docker rm -f `docker ps --no-trunc -a | grep gluster | cut -d" " -f1` 1>/dev/null 2>&1

echo "deleting vgs and pvs"
pvscan --cache  1>/dev/null 2>&1 
pvs   1>/dev/null 2>&1
for pv in `losetup --list | grep brick | cut -d" " -f1` ;
do
	for vg in $(eval "pvs | grep $pv"  | awk {'print $2'}) ;
	do
		echo "........deleting vg $vg"
		vgremove -ff -y $vg 1>/dev/null 2>&1 
	done;
	echo "....deleting pv $pv "
	pvremove --force $pv  1>/dev/null 2>&1
done


echo "deleting loop back devices"
losetup -d `losetup --list | grep brick | cut -d" " -f1` 1>/dev/null 2>&1


echo "deleting metadata from .minister"
rm -rf ${PWD}/.minister
