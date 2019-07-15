echo ">   Staging Cloudctl Profile ..."
cat <<EOF >/tmp/lxd-profile-cloudctl.yaml
config:
  linux.kernel_modules: ip6table_filter,iptable_filter
  security.nesting: "true"
  security.privileged: "true"
  user.network-config: |
    version: 2
    ethernets:
      eth0:
        dhcp4: true
        dhcp6: false
      eth1:
        dhcp4: false
        dhcp6: false
        addresses: [ ${ministack_SUBNET}.3/24 ]
  user.user-data: |
    #cloud-config
    package_upgrade: true
    packages:
      - jq
      - git
      - vim-enhanced
      - tree
      - tmux
      - lnav
      - byobu
      - snapd
      - httpd
      - squashfuse
      - python-pip
      - python3-openstackclient
      - python3-keystoneclient
      - python3-cinderclient
      - python3-swiftclient
      - python3-glanceclient
      - python3-novaclient
      - python3-neutronclient
    users:
      - name: ${ministack_UNAME}
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh_import_id: ${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}
    runcmd:
      - [echo, "'CLOUDCTL-DBG: Start RUNCMD'"]
      - [echo, "CLOUDINIT-DBG: runcmd 0.0 - base prep"]
      - [pip, install, requests]
      - [pip, install, ssh-import-id]
      - [update-alternatives, "--set", "editor", "/usr/bin/vim"]
      - [echo, "source /etc/ccio/mini-stack/profile", ">>", "/etc/bashrc"]
      - ["ssh-import-id", "${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}"]
      - [echo, "CLOUDINIT-DBG: runcmd 2.0 - user prep ${ministack_UNAME}"]
      - [su, "-l", "${ministack_UNAME}", "-c", "/bin/bash -c 'byobu-enable'"]
      - [su, "-l", "${ministack_UNAME}", "/bin/bash", "-c", "ssh-keygen -f ~/.ssh/id_rsa -N ''"]
      - [su, "-l", "${ministack_UNAME}", "/bin/bash", "-c", "ssh-import-id ${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}"]
      - [chown, "-R", "${ministack_UNAME}:${ministack_UNAME}", "/home/${ministack_UNAME}"]
      - [mkdir, "-p", "/etc/ccio/mini-stack"]
      - [git, clone, "https://github.com/containercraft/mini-stack.git", "/var/www/html/mini-stack"]
      - [ln, "-s", "/var/www/html/mini-stack", "/root/mini-stack"]
      - [echo, "CLOUDINIT-DBG: runcmd 0.0 - cloud-config runcmd complete ... rebooting"]
      - [reboot]
description: ccio mini-stack cloudctl container profile
devices:
  eth0:
    name: eth0
    nictype: macvlan
    parent: external
    type: nic
  eth1:
    name: eth1
    nictype: macvlan
    parent: internal
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: cloudctl
EOF

# Detect && Purge 'cloudctl' Profile
echo ">   Checking for & Removing Pre-Existing CloudCTL Profile ..."
[[ $(lxc profile show cloudctl 2>&1 1>/dev/null ; echo $?) != 0 ]] || lxc profile delete cloudctl

# Create && Write Profile
lxc profile create cloudctl

echo ">   Loading CloudCTL Cloud Init Data"
lxc profile edit cloudctl < <(cat /tmp/lxd-profile-cloudctl.yaml)
