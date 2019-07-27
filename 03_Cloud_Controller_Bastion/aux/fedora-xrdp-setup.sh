#!/bin/bash

run_xrdp_setup () {
sudo dnf groupinstall "Fedora Workstation" -y
sudo dnf install xrdp 
sudo systemctl start xrdp
sudo systemctl enable xrdp
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --add-port 3389/tcp --permanent
sudo firewall-cmd --reload
}
run_xrdp_setup
