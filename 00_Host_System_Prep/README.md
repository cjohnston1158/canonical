# Part 0 -- Host System Preparation

#### Review checklist of prerequisites:
  1. You have a fresh install of Fedora 30 on a machine with no critical data or services on it
  2. You are familiar with and able to ssh between machines
  3. You have an ssh key pair, and uploaded the public key to your [Launchpad](https://launchpad.net/) or [Github](https://github.com/) account
  4. Run commands as root
  5. Recommended: Follow these guides using ssh to copy/paste commands as you read along

#### 01. Base Setup
```sh
hostnamectl set-hostname host01.mini-stack.cloud
```
#### 01. Update System && Install helper packages
```sh
dnf update -y && dnf upgrade -y && dnf distro-sync -y
dnf install neovim lnav openssh-server snapd pastebinit network-scripts python-pip
pip install requests && pip install ssh-import-id
```
#### 02. Create CCIO Mini-Stack Profile
```sh
wget https://git.io/fjXkH -qO /tmp/profile && source /tmp/profile
```
#### 03. Append GRUB Options for Libvirt & Networking Kernel Arguments
```sh
sed -i 's/quiet/debug intel_iommu=on iommu=pt kvm_intel.nested=1 net.ifnames=0 biosdevname=0 pci=noaer/g' /etc/default/grub
```
```sh
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```
#### 04. Reboot
-------
## OPTIONAL
##### OPT 01. Switch default editor from nano to vim
```sh
update-alternatives --set editor /usr/bin/vim
```
##### OPT 02. Disable Lid Switch Power/Suspend (if building on a laptop)
```sh
sed -i 's/^#HandleLidSwitch=suspend/HandleLidSwitch=ignore/g' /etc/systemd/logind.conf
sed -i 's/^#HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=ignore/g' /etc/systemd/logind.conf
```
##### OPT 03. Disable default GUI startup  (DESKTOP OS)
  NOTE: Use command `systemctl start graphical.target` to manually start full GUI environment at will
```sh
systemctl set-default multi-user.target
```
-------
## Next sections
- [Part 1 Single Port Host OVS Network]
- [Part 2 LXD On Open vSwitch Network]
- [Part 3 LXD Gateway & Firwall for Open vSwitch Network Isolation]
- [Part 4 KVM On Open vSwitch]
- [Part 5 MAAS Region And Rack Server on OVS Sandbox]
- [Part 6 MAAS Connect POD on KVM Provider]
- [Part 7 Juju MAAS Cloud]
- [Part 8 OpenStack Prep]

<!-- Markdown link & img dfn's -->
[Part 0 Host System Prep]: ../0_Host_System_Prep
[Part 1 Single Port Host OVS Network]: ../1_Single_Port_Host-Open_vSwitch_Network_Configuration
[Part 2 LXD On Open vSwitch Network]: ../2_LXD-On-OVS
[Part 3 LXD Gateway & Firwall for Open vSwitch Network Isolation]: ../3_LXD_Network_Gateway
[Part 4 KVM On Open vSwitch]: ../4_KVM_On_Open_vSwitch
[Part 5 MAAS Region And Rack Server on OVS Sandbox]: ../5_MAAS-Rack_And_Region_Ctl-On-Open_vSwitch
[Part 6 MAAS Connect POD on KVM Provider]: ../6_MAAS-Connect_POD_KVM-Provider
[Part 7 Juju MAAS Cloud]: ../7_Juju_MAAS_Cloud
[Part 8 OpenStack Prep]: ../8_OpenStack_Deploy
