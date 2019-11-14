#!/bin/bash
echo ">   Staging MaasCTL Profile ..."

mac_ETH1_HWADDR="$(echo "maasctl external eth1 ${ministack_SUBNET}" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02\:\1\:\2\:\3\:\4\:\5/')"

cat <<EOF >/tmp/lxd-profile-maasctl.yaml
config:
  boot.autostart: "true"
  boot.autostart.delay: "5"
  raw.lxc: |-
    lxc.cgroup.devices.allow = c 10:237 rwm
    lxc.apparmor.profile = unconfined
    lxc.cgroup.devices.allow = b 7:* rwm
  security.privileged: "true"
  user.network-config: |
    version: 2
    ethernets:
      eth0:
        dhcp4: false
        dhcp6: false
        addresses: [ ${ministack_SUBNET}.10/24 ]
        gateway4: ${ministack_SUBNET}.1
        nameservers:
          addresses: [ 8.8.8.8,1.1.1.1 ]
          search: [ maas ]
      eth1:
        dhcp4: true
        dhcp6: false
        macaddress: "${mac_ETH1_HWADDR}"
  user.user-data: |
    #cloud-config
    package_upgrade: true
    ssh_import_id: ${ccio_SSH_UNAME}
    apt:
      preserve_sources_list: true
      sources:
        maas:
          source: "ppa:maas/stable"
    packages:
      - bridge-utils
      - qemu-kvm
      - libvirt-bin
      - virtinst
      - jq
      - lnav
      - python
    runcmd:
      - [cp, "-f", "/etc/skel/.bashrc", "/root/.bashrc"]
      - [apt-get, autoremove, "-y"]
      - [virsh, net-undefine, default]
      - [virsh, net-destroy, default]
      - [apt-get, install, "-y", maas, "--install-recommends"]
      - [chsh, -s, /bin/bash, maas]
      - ["wget", "-qO", "/root/maas-nodes-discover", "http://${ministack_SUBNET}.3/mini-stack/05_MAAS_Region_And_Rack_Controller/aux/maas-nodes-discover"]
      - [chmod, "+x", "/root/maas-nodes-discover"]
      - [ln, -f, -s, "/root/maas-nodes-discover", /usr/bin/maas-nodes-discover]
      - ["wget", "-qO", "/root/login-maas-cli", "http://${ministack_SUBNET}.3/mini-stack/05_MAAS_Region_And_Rack_Controller/aux/login-maas-cli.sh"]
      - [chmod, "+x", "/root/login-maas-cli"]
      - [ln, -f, -s, "/root/login-maas-cli", /usr/bin/login-maas-cli]
      - [su, -l, maas, /bin/bash, -c, "ssh-keygen -f ~/.ssh/id_rsa -N ''"]
      - [su, -l, maas, /bin/bash, -c, "ssh-import-id", "${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}"]
      - [maas, createadmin, --username=admin, --password=admin, --email=admin, --ssh-import, "${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}"]
      - [login-maas-cli]
      - [reboot]
description: ccio mini-stack maasctl container profile
devices:
  eth0:
    name: eth0
    nictype: macvlan
    parent: internal
    type: nic
  kvm:
    path: /dev/kvm
    type: unix-char
  loop0:
    path: /dev/loop0
    type: unix-block
  loop1:
    path: /dev/loop1
    type: unix-block
  loop2:
    path: /dev/loop2
    type: unix-block
  loop3:
    path: /dev/loop3
    type: unix-block
  loop4:
    path: /dev/loop4
    type: unix-block
  loop5:
    path: /dev/loop5
    type: unix-block
  loop6:
    path: /dev/loop6
    type: unix-block
  loop7:
    path: /dev/loop7
    type: unix-block
  root:
    path: /
    pool: default
    type: disk
name: maasctl
EOF

# Detect && Purge 'maasctl' Profile
echo ">   Checking for & Removing Pre-Existing MaasCTL Profile ..."
[[ $(lxc profile show maasctl 2>&1 1>/dev/null ; echo $?) != 0 ]] || lxc profile delete maasctl

# Create && Write Profile
lxc profile create maasctl

echo ">   Loading MaasCTL Cloud Init Data"
lxc profile edit maasctl < <(cat /tmp/lxd-profile-maasctl.yaml)
