#!/bin/bash

IMAGE="brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/rhgs3/rhgs-server-rhel7"
echo "Make sure you create network using 'docker network create --subnet 172.18.0.0/16 heketi-test'"

if [ "$#" -le 1 ]; then
    echo "Illegal number of parameters"
    echo "usage: ./create_containers.sh number_of_gluster_nodes number_of_devices_per_node image_name"
    exit 1
fi

mkdir ${PWD}/.minister
NODE_COUNT=$1
DISK_COUNT=$2
DISK_SIZE="500G"
IMAGE=$3
DOCKER_SUBNET="172.18.0."
DOCKER_NETWORK_NAME="heketi-test"

ssh-keygen -t rsa -N '' -f ${PWD}/.minister/heketi-key 2>&1 1>/dev/null
cp ${PWD}/.minister/heketi-key.pub ${PWD}/.minister/authorized_keys

for loop_num in {0..64};
do
	mknod /dev/loop${loop_num} -m0660 b 7 ${loop_num} 2>/dev/null
done

for n in $(seq 1 $NODE_COUNT);
	do mkdir -p ${PWD}/.minister/node${n};
        myip=`expr $n + 1`
	mkdir -p ${PWD}/.minister/node${n}/etc-glusterfs;
	mkdir -p ${PWD}/.minister/node${n}/disks;
	mkdir -p ${PWD}/.minister/node${n}/var-lib-glusterd;
	mkdir -p ${PWD}/.minister/node${n}/var-log-glusterfs;
	mkdir -p ${PWD}/.minister/node${n}/var-lib-heketi;
	docker run -v ${PWD}/.minister/node${n}/etc-glusterfs:/etc/glusterfs:z \
		   -v ${PWD}/.minister/node${n}/var-lib-glusterd:/var/lib/glusterd:z \
                   -v ${PWD}/.minister/node${n}/var-log-glusterfs:/var/log/glusterfs:z \
                   -v ${PWD}/.minister/node${n}/var-lib-heketi:/var/lib/heketi:z \
                   -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                   -v /dev:/dev:z \
                   -v ${PWD}/.minister/node${n}/disks:/disks:z \
                   -v ${PWD}/.minister/authorized_keys:/root/.ssh/authorized_keys:z \
                   -d --privileged=true --name gluster-node${n} \
                   --net ${DOCKER_NETWORK_NAME} \
		   --ip ${DOCKER_SUBNET}${myip} \
		   --hostname gluster-node${n} \
                   $IMAGE
	for m in $(seq 1 $DISK_COUNT);
		 do truncate -s $DISK_SIZE ${PWD}/.minister/node${n}/disks/brick${m};
                 docker exec -it gluster-node${n} losetup --find --show /disks/brick${m} 2>&1 1>/dev/null
	done
        #docker exec -it gluster-node${n} sed -i 's/udev_sync\s*=\s*1/udev_sync = 0/' /etc/lvm/lvm.conf
        #docker exec -it gluster-node${n} sed -i 's/udev_rules\s*=\s*1/udev_rules = 0/' /etc/lvm/lvm.conf
        #docker exec -it gluster-node${n} sed -i 's/use_lvmetad\s*=\s*1/use_lvmetad = 0/' /etc/lvm/lvm.conf
        #docker exec -it gluster-node${n} pvscan --cache

done




