# Part 08 -- Juju MAAS Cloud Provider
###### Configure the host Libvirt daemon as an automated MAAS cloud virtual machine provider for JujuCTL

-------
Prerequisites:
- [Part 00 Host System Prep]
- [Part 01 Single Port Host OVS Network Config]
- [Part 02 LXD On Open vSwitch Networks]
- [Part 03 Build CloudCTL LXD Bastion]
- [Part 04 LXD Network Gateway]
- [Part 05 MAAS Region And Rack Controller]
- [Part 06 Install Libvirt/KVM on OVS Networks]
- [Part 07 MAAS Libvirt POD Provider]

![CCIO_Hypervisor - KVM-On-Open-vSwitch](web/drawio/jujuctl-build.svg)

-------
#### 01. Enroll MAAS as Juju Cloud Provider
````sh
wget -qO- http://${ministack_SUBNET}.3/mini-stack/08_Juju_MaaS_Cloud_Configuration/aux/add-maas-cloud-provider.sh | bash
lxc exec cloudctl -- su -l ${ministack_uname} -c 'source /tmp/juju-enroll-maas-provider.sh'
````
#### 02. Build 'jujuctl' libvirt juju controller vm
````sh
wget -qO- http://${ministack_SUBNET}.3/mini-stack/08_Juju_MaaS_Cloud_Configuration/aux/virt-inst-jujuctl-node.sh | bash
````
#### 03. Import JujuCTL as MaaS Node
````sh
lxc exec maasctl -- login-maas-cli
lxc exec maasctl -- maas-nodes-discover
````
#### 04. Tag JujuCtl Libvirt VM
````sh
lxc exec maasctl -- /bin/bash -c "wget -qO- http://${ministack_SUBNET}.3/mini-stack/08_Juju_MaaS_Cloud_Configuration/aux/maas-tag-nodes.sh | bash"
````
#### 05. Bootstrap Juju Controller
````sh
lxc ${ministack_UNAME} cloudctl
juju bootstrap --bootstrap-series=bionic --config bootstrap-timeout=1800 --constraints "tags=jujuctl" maasctl jujuctl
````
#### 06. Create Juju Model (on cloudctl)
````sh
juju add-model mini-stack
exit
````
-------
## Next sections
- [Part 09 Build OpenStack Cloud]
- [Part 10 Build Kubernetes Cloud]

<!-- Markdown link & img dfn's -->
[Part 00 Host System Prep]: ../00_Host_System_Prep
[Part 01 Single Port Host OVS Network Config]: ../01_Single_Port_Host_OpenVSwitch_Config
[Part 02 LXD On Open vSwitch Networks]: ../02_LXD_On_OVS
[Part 03 Build CloudCTL LXD Bastion]: ../03_Cloud_Controller_Bastion
[Part 04 LXD Network Gateway]: ../04_LXD_Network_Gateway
[Part 05 MAAS Region And Rack Controller]: ../05_MAAS_Region_And_Rack_Controller
[Part 06 Install Libvirt/KVM on OVS Networks]: ../06_Libvirt_On_Open_vSwitch
[Part 07 MAAS Libvirt POD Provider]: ../07_MAAS_Libvirt_Pod_Provider
[Part 08 Juju MAAS Cloud Provider]: ../08_Juju_MaaS_Cloud_Configuration
[Part 09 Build OpenStack Cloud]: ../09_OpenStack_Cloud
[Part 10 Build Kubernetes Cloud]: ../10_Kubernetes_Cloud
