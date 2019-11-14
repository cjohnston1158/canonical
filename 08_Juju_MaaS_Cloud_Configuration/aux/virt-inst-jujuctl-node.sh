#!/bin/bash

#################################################################################
# Hardware Profile
vm_CPU=4
root_DISK=48   # in Gigabytes
vm_RAM=4096    # in Megabytes
vm_COUNT=01    # Set VM spawn count
storage_POOL="/var/lib/libvirt/images"
name_BASE="jujuctl"

#################################################################################
# If set to 'true' will disable sleep interval between spawn loops
run_FAST="true"

spawn_build () {
virt-install \
    --pxe \
    --hvm \
    --noreboot \
    --noautoconsole \
    --graphics none \
    --os-type=Linux \
    --vcpus=${vm_CPU} \
    --memory=${vm_RAM} \
    --name=${name_FULL} \
    --cpu host-passthrough \
    --os-variant=ubuntu18.04 \
    --boot 'network,hd,useserial=on' \
    --description 'juju maas cloud jujuctl controller node' \
    --network network=internal,model=virtio,mac=${eth0_HWADDRESS} \
    --disk path=${storage_POOL}/${name_FULL}_vda.qcow2,format=raw,bus=virtio,cache=unsafe,size=${root_DISK}

# Prevent the VM from pxe booting to autodiscovery in maas
sleep 2 && virsh destroy ${name_FULL}

}

spawn_prep () {
eth0_HWADDRESS=$(echo "${name_FULL} internal eth0" | md5sum \
    | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02\\:\1\\:\2\\:\3\\:\4\\:\5/')
}

run_spawn () {
for count in $(seq -w 01 ${vm_COUNT}); do
       
       # Set VM Name & Declare Build
       name_FULL="${name_BASE}"
       echo "Building ${name_FULL}"

       # Set variables for spawn build
       spawn_prep
       spawn_build

       # If run fast disabled will pause for anti flood safety interval
       [[ $run_FAST == "true" ]] || sleep 30

done
}

run_spawn
