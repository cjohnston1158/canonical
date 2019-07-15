#!/bin/bash
set -x

run_stage_cloudctl_init () {
cat <<EOINIT >/tmp/cloudctl-fedora-init.sh
#!/bin/bash
set -x

run_pkg_inst () {
dnf update -y
dnf install -y \
  jq git vim-enhanced tree tmux lnav byobu snapd httpd openssh-server \
  squashfuse python-pip python3-openstackclient python3-keystoneclient \
  python3-cinderclient python3-swiftclient python3-glanceclient \
  python3-novaclient python3-neutronclient

pip install requests
pip install ssh-import-id

systemctl enable sshd
systemctl enable httpd
}

run_add_user () {
adduser --user-group --shell /bin/bash --create-home \
  --home-dir /home/${ministack_UNAME} --groups wheel,lxd ${ministack_UNAME} 
  
ssh-import-id ${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}
su -l ${ministack_UNAME} -c /bin/bash -c 'byobu-enable'
su -l ${ministack_UNAME} /bin/bash -c "ssh-keygen -f ~/.ssh/id_rsa -N ''"
echo "${ministack_UNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/visudo.d/${ministack_UNAME} 
su -l ${ministack_UNAME} /bin/bash -c "ssh-import-id ${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}"
chown -R ${ministack_UNAME}:${ministack_UNAME} /home/${ministack_UNAME}
ln -s /var/www/html/mini-stack /home/${ministack_UNAME}/mini-stack
update-alternatives --set editor /usr/bin/vim
echo "source /etc/ccio/mini-stack/profile" >> /etc/bashrc
}


run_add_ms_mirror () {
mkdir -p /etc/ccio/mini-stack
git clone https://github.com/containercraft/mini-stack.git /home/${ministack_UNAME}/mini-stack
cd /home/${ministack_UNAME}/mini-stack && git checkout master-mini-stack-rpm && cd ~
ln -s /home/${ministack_UNAME}/mini-stack /var/www/html/mini-stack
ln -s /var/www/html/mini-stack /root/mini-stack
}

run_network_config () {
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-eth0
NAME="eth0"
DEVICE="eth0"
ONBOOT="yes"
NETBOOT="yes"
BOOTPROTO="dhcp"
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_FAILURE_FATAL="no"
EOF

cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-eth1
NAME="eth1"
DEVICE="eth1"
ONBOOT="yes"
NETBOOT="yes"
BOOTPROTO="static"
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_FAILURE_FATAL="no"
EOF
}

run_pkg_inst 
run_add_user 
run_add_ms_mirror 
run_network_config 
reboot
EOINIT
}

run_stage_profile () {
cat <<EOF >/tmp/lxd-profile-cloudctl.yaml
config:
  linux.kernel_modules: ip6table_filter,iptable_filter
  security.nesting: "true"
  security.privileged: "true"
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
}

run_apply_lxd_profile () {
# Detect && Purge 'cloudctl' Profile
echo ">   Checking for & Removing Pre-Existing CloudCTL Profile ..."
[[ $(lxc profile show cloudctl 2>&1 1>/dev/null ; echo $?) != 0 ]] || lxc profile delete cloudctl

# Create && Write Profile
lxc profile create cloudctl

echo ">   Loading CloudCTL Config Script"
lxc profile edit cloudctl < <(cat /tmp/lxd-profile-cloudctl.yaml)

echo ">   Prep complete, Run the following to deploy bastion:
      lxc launch images:fedora/29 cloudctl -p cloudctl
      lxc file push /tmp/cloudctl-fedora-init.sh cloudctl/tmp/cloudctl-fedora-init.sh
      lxc exec cloudctl -- source /tmp/cloudctl-fedora-init.sh
     "
}

run_core () {
run_stage_cloudctl_init 
run_stage_profile 
run_apply_lxd_profile 
}

run_core
