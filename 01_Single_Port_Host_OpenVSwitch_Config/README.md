# Part 01 -- Single Port Host OpenvSwitch Configuration
#### Provision a host `external` virtual network viable for cloud scale emulation and testing.
WARNING: Exercise caution when performing this procedure remotely as this may cause loss of connectivity.    

-------
## Prerequisites:
- [Part 00 Host System Prep]

>
> Overview of Steps:
> - Install required packages
> - Enable Open vSwitch Service & Confirm running status
> - Create base OVS Bridge for interfacing with local physical network
> - Create a virtual host ethernet port on the 'external' bridge
> - Impliment 'systemd-networkd' workaround RE: [BUG: 1728134]

![CCIO_Hypervisor-mini_Stack_Diagram](web/drawio/single-port-ovs-host.svg)

-------
#### 01. Install && enable OpenVSwitch Package
```sh
dnf install -y openvswitch network-scripts
```
#### 02. Write physical network ingress port ifcfg Config [EG: 'eth0']
  - NOTE: export name of nic device your primary host network traffic will traverse (EG: 'eth0' in this example)
```sh
export external_NIC="eth0"
```
```sh
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-${external_NIC}
HOTPLUG=no
ONBOOT="yes"
BOOTPROTO="none"
TYPE="OVSPort"
DEVICETYPE="ovs"
NM_CONTROLLED="no"
OVS_BRIDGE="external"
NAME="${external_NIC}"
DEVICE="${external_NIC}"
HWADDR="$(ip -o link show ${external_NIC} | awk '{print $(NF-2)}')"
UUID=$(uuidgen ${external_NIC})
EOF
```
#### 03. Write OVS  Bridge 'external' ifcfg Config
```sh
export iface_MACADDR=$(echo "${HOSTNAME} ${ministack_SUBNET} external" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02\:\1\:\2\:\3\:\4\:\5/')
```
```sh
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-external
DELAY=0
HOTPLUG=no
IPV6INIT=no
ONBOOT="yes"
NAME="external"
DEVICE="external"
BOOTPROTO=static
NM_CONTROLLED="no"
DEVICETYPE="ovs"
TYPE="OVSBridge"
OVSBOOTPROTO="static"
GATEWAY="$(ip r | grep -v "127.0" | awk '/default /{print $3}' | head -n 1)"
IPADDR=$(ip -o a s $(ip r | grep -v "127.0" | awk '/default /{print $5}' | head -n 1) | awk -F'[ /]' '/inet /{print $7}')
NETMASK="255.255.255.0"
MACADDR="${iface_MACADDR}"
OVS_EXTRA="set bridge \$DEVICE other-config:hwaddr=\$MACADDR"
UUID=$(uuidgen internal)
EOF
```
#### 04. Write OVS bridge 'internal' ifcfg Config
```sh
export iface_MACADDR=$(echo "${HOSTNAME} ${ministack_SUBNET} internal" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02\:\1\:\2\:\3\:\4\:\5/')
```
````sh
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-internal
DELAY=0
HOTPLUG=no
IPV6INIT=no
ONBOOT="yes"
NAME="internal"
DEVICETYPE="ovs"
DEVICE="internal"
TYPE="OVSBridge"
BOOTPROTO="static"
NM_CONTROLLED="no"
OVSBOOTPROTO="static"
IPADDR="${ministack_SUBNET}.2"
MACADDR="${iface_MACADDR}"
NETMASK="255.255.255.0"
OVS_EXTRA="set bridge \$DEVICE other-config:hwaddr=\$MACADDR"
UUID=$(uuidgen external)
EOF
````
#### 08. Add OVS Orphan Port Cleaning Utility
NOTE: Use command `ovs-clear` to remove orphaned 'not found' ports as needed
````sh
cat <<EOF >/usr/bin/ovs-clear
#!/bin/bash
# ovs-clear - This script will search and destroy orphaned ovs port
for i in \$(ovs-vsctl show | awk '/error: /{print \$7}'); do
    ovs-vsctl del-port \$i;
done
clear && ovs-vsctl show
EOF
````
````sh
chmod +x /usr/bin/ovs-clear && ovs-clear
````
#### 09. Build OVS Bridge external and apply configuration
````sh
cat <<EOF >/tmp/external-setup
#!/bin/bash
run_netconfig () {
systemctl enable network
systemctl enable openvswitch
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl start openvswitch
ovs-vsctl add-br external
ovs-vsctl add-br internal
systemctl start network
}
run_netconfig
ovs-clear
EOF
````
````sh
source /tmp/external-setup
````
-------
## Next sections
- [Part 02 LXD On Open vSwitch Networks]
- [Part 03 Build CloudCTL LXD Bastion]
- [Part 04 LXD Network Gateway]
- [Part 05 MAAS Region And Rack Controller]
- [Part 06 Install Libvirt/KVM on OVS Networks]
- [Part 07 MAAS Libvirt POD Provider]
- [Part 08 Juju MAAS Cloud Provider]
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
