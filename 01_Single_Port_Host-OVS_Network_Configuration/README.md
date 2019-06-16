# Part 1 -- Single Port Host Open vSwitch Network Configuration
#### Provision a host virtual entry network viable for cloud scale emulation and testing.
WARNING: Exercise caution when performing this procedure remotely as this may cause loss of connectivity.    

-------
## Prerequisites:
- [Part 0 Host System Prep]

>
> Overview of Steps:
> - Install required packages
> - Enable Open vSwitch Service & Confirm running status
> - Create base OVS Bridge for interfacing with local physical network
> - Create a virtual host ethernet port on the 'external' bridge
> - Impliment 'systemd-networkd' workaround RE: [BUG: 1728134]

![CCIO_Hypervisor-mini_Stack_Diagram](web/drawio/single-port-ovs-host.svg)

-------
#### 01. Update system && Install Packages
```sh
apt install -y openvswitch-switch
```
#### 02. Write physical network ingress port Networkd Config [EG: 'eth0']
  - NOTE: export name of nic device your primary host network traffic will traverse (EG: 'eth0' in this example)
```sh
export external_NIC="eth0"
```
```sh
cat <<EOF >/etc/systemd/network/${external_NIC}.network                                                    
[Match]
Name=${external_NIC}

[Network]
DHCP=no
IPv6AcceptRA=no
LinkLocalAddressing=no
EOF

```
#### 03. Write OVS  Bridge 'external' Networkd Config
```sh
cat <<EOF >/etc/systemd/network/external.network                                                    
[Match]
Name=external

[Network]
DHCP=no
IPv6AcceptRA=no
LinkLocalAddressing=no
EOF

```
#### 04. Write OVS bridge 'internal' Networkd Config
````sh
cat <<EOF >/etc/systemd/network/internal.network                                                    
[Match]
Name=internal

[Network]
DHCP=no
IPv6AcceptRA=no
LinkLocalAddressing=no
EOF
````
#### 05. Disable original Netplan Config
````sh
for yaml in $(ls /etc/netplan/); do sed -i 's/^/#/g' /etc/netplan/${yaml}; done
````
#### 06. Write mgmt0 interface netplan config
````sh
cat <<EOF >/etc/netplan/80-mgmt0.yaml
# For more configuration examples, see: https://netplan.io/examples                                                   
# OVS 'external' Bridge Port 'mgmt0' Configuration
network:
  version: 2
  renderer: networkd
  ethernets:
    mgmt0:
      optional: true
      addresses:
        - $(ip a s ${external_NIC} | awk '/inet /{print $2}' | head -n 1)
      gateway4: $(ip r | awk '/default /{print $3}' | head -n 1)
      nameservers:
        addresses: 
          - $(systemd-resolve --status | grep "DNS Server" | awk '{print $3}')
EOF

````
#### 07. Write mgmt1 interface netplan config
````sh
cat <<EOF > /etc/netplan/80-mgmt1.yaml
# Configure mgmt1 on 'internal' bridge
# For more configuration examples, see: https://netplan.io/examples
network:
  version: 2
  renderer: networkd
  ethernets:
    mgmt1:
      optional: true
      dhcp4: false
      dhcp6: false
      addresses:
        - ${ministack_SUBNET}.2/24
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
#### 09. Build OVS Bridge external, port mgmt0, and apply configuration
````sh
cat <<EOF >/tmp/external-mgmt0-setup
net_restart () {
ovs-vsctl \
  add-br external -- \
  add-port external ${external_NIC} -- \
  add-port external mgmt0 -- \
  set interface mgmt0 type=internal -- \
  set interface mgmt0 mac="$(echo "${HOSTNAME} external mgmt0" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02\\:\1\\:\2\\:\3\\:\4\\:\5/')"
systemctl restart systemd-networkd.service && netplan apply --debug
ovs-clear
}
net_restart
EOF

````
````sh
source /tmp/external-mgmt0-setup && reboot
````
#### 10. Build OVS Bridge external, port mgmt1, and apply configuration
````sh
cat <<EOF >/tmp/internal-mgmt1-setup
ovs-vsctl \
  add-br internal -- \
  add-port internal mgmt1 -- \
  set interface mgmt1 type=internal -- \
  set interface mgmt1 mac="$(echo "$HOSTNAME internal mgmt1" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02\\:\1\\:\2\\:\3\\:\4\\:\5/')"
systemctl restart systemd-networkd.service && netplan apply --debug
ovs-clear
EOF

````
````sh
source /tmp/internal-mgmt1-setup && reboot
````

-------
## Next sections
- [Part 2 LXD On Open vSwitch Network]
- [Part 3 LXD Gateway & Firwall for Open vSwitch Network Isolation]
- [Part 4 KVM On Open vSwitch]
- [Part 5 MAAS Region And Rack Server on OVS Sandbox]
- [Part 6 MAAS Connect POD on KVM Provider]
- [Part 7 Juju MAAS Cloud]
- [Part 8 OpenStack Prep]

<!-- Markdown link & img dfn's -->
[BUG: 1728134]: https://bugs.launchpad.net/netplan/+bug/1728134
[Part 0 Host System Prep]: ../0_Host_System_Prep
[Part 1 Single Port Host OVS Network]: ../1_Single_Port_Host-Open_vSwitch_Network_Configuration
[Part 2 LXD On Open vSwitch Network]: ../2_LXD-On-OVS
[Part 3 LXD Gateway & Firwall for Open vSwitch Network Isolation]: ../3_LXD_Network_Gateway
[Part 4 KVM On Open vSwitch]: ../4_KVM_On_Open_vSwitch
[Part 5 MAAS Region And Rack Server on OVS Sandbox]: ../5_MAAS-Rack_And_Region_Ctl-On-Open_vSwitch
[Part 6 MAAS Connect POD on KVM Provider]: ../6_MAAS-Connect_POD_KVM-Provider
[Part 7 Juju MAAS Cloud]: ../7_Juju_MAAS_Cloud
[Part 8 OpenStack Prep]: ../8_OpenStack_Deploy
