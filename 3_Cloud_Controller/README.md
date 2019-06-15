# Part 3 -- Build 'cloudctl' LXD Cloud Controller Bastion
###### Build LXD Bastion for operating the mini-stack cloud
-------
## Prerequisites:
- [Part 0 Host System Prep]
- [Part 1 Single Port Host OVS Network]
- [Part 2 LXD On Open vSwitch Network]
- [Part 3 LXD Gateway & Firwall for Open vSwitch Network Isolation]
- [Part 4 KVM On Open vSwitch]
- [Part 5 MAAS Region And Rack Server on OVS Sandbox]
- [Part 6 MAAS Connect POD on KVM Provider]
![CCIO Hypervisor - JujuCTL Cloud Controller](web/drawio/juju_maas_cloud_controller.svg)
-------
#### 01. Build CloudCTL Profile
````sh
wget -qO- https://git.io/fjaUm | bash
````
#### 02. Build CloudCtl Container
````sh
lxc launch ubuntu:bionic cloudctl -p cloudctl
lxc exec cloudctl -- tail -f /var/log/cloud-init-output.log
````
  - NOTE: wait for cloud-init to finish configuring the container, this may take some time...
#### 03. Import CloudCtl ssh keys on host
````sh
lxc exec cloudctl -- /bin/bash -c "cat /home/ubuntu/.ssh/id_rsa.pub" >>/root/.ssh/authorized_keys
lxc exec cloudctl -- /bin/bash -c "cat /home/${ministack_UNAME}/.ssh/id_rsa.pub" >>/root/.ssh/authorized_keys
````
#### 04. Set User Password
````sh
lxc exec cloudctl -- passwd ${ministack_UNAME}
````
-------
## OPTIONAL: Install Ubuntu Desktop & RDP for Remote GUI Control
#### OPT 01. Launch LXD Ubuntu Desktop Environment + xRDP Setup Script
```sh
lxc stop cloudctl; sleep 1; lxc snapshot cloudctl pre-gui-config; lxc start cloudctl
lxc exec cloudctl -- /bin/bash -c 'wget -qO- https://git.io/fjaJD | bash'
lxc start cloudctl ; sleep 4 ; lxc list
```
  - NOTE: Desktop Environment consumes an additional ~900M RAM & XGB Disk Space
#### OPT 02. CloudCTL is now accessible over RDP via it's IP address
-------
## Continue to the next section
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
