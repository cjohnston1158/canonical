#!/bin/bash

cat <<EOF >/tmp/curtin_userdata
#cloud-config
debconf_selections:
 maas: |
  {{for line in str(curtin_preseed).splitlines()}}
  {{line}}
  {{endfor}}
early_commands:
{{if third_party_drivers and driver}}
  {{py: key_string = ''.join(['\\x%x' % x for x in driver['key_binary']])}}
  {{if driver['key_binary'] and driver['repository'] and driver['package']}}
  driver_00_get_key: /bin/echo -en '{{key_string}}' > /tmp/maas-{{driver['package']}}.gpg
  driver_01_add_key: ["apt-key", "add", "/tmp/maas-{{driver['package']}}.gpg"]
  {{endif}}
  {{if driver['repository']}}
  driver_02_add: ["add-apt-repository", "-y", "deb {{driver['repository']}} {{node.get_distro_series()}} main"]
  {{endif}}
  {{if driver['package']}}
  driver_03_update_install: ["sh", "-c", "apt-get update --quiet && apt-get --assume-yes install {{driver['package']}}"]
  {{endif}}
  {{if driver['module']}}
  driver_04_load: ["sh", "-c", "depmod && modprobe {{driver['module']}} || echo 'Warning: Failed to load module: {{driver['module']}}'"]
  {{endif}}
{{else}}
  driver_00: ["sh", "-c", "echo third party drivers not installed or necessary."]
{{endif}}
late_commands:
  maas: [wget, '--no-proxy', {{node_disable_pxe_url|escape.json}}, '--post-data', {{node_disable_pxe_data|escape.json}}, '-O', '/dev/null']
  add_user: ["curtin", "in-target", "--", "useradd", "-s", "/bin/bash", "-m", "-d", "/home/${ccio_SSH_UNAME}", "-p", "${ccio_PWD_SALT}", "${ccio_SSH_UNAME}"]
  add_user_sudoer: ["curtin", "in-target", "--", "/usr/sbin/usermod", "-aG", "sudo", "${ccio_SSH_UNAME}"]
  add_user_keys: ["curtin", "in-target", "--", "su", "-l", "${ccio_SSH_UNAME}", "/bin/bash", "-c", "ssh-import-id ${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}"]
  add_user_keys: ["curtin", "in-target", "--", "ssh-import-id", "${ccio_SSH_SERVICE}:${ccio_SSH_UNAME}"]
{{if third_party_drivers and driver}}
  {{if driver['key_binary'] and driver['repository'] and driver['package']}}
  driver_00_key_get: curtin in-target -- sh -c "/bin/echo -en '{{key_string}}' > /tmp/maas-{{driver['package']}}.gpg"
  driver_02_key_add: ["curtin", "in-target", "--", "apt-key", "add", "/tmp/maas-{{driver['package']}}.gpg"]
  {{endif}}
  {{if driver['repository']}}
  driver_03_add: ["curtin", "in-target", "--", "add-apt-repository", "-y", "deb {{driver['repository']}} {{node.get_distro_series()}} main"]
  {{endif}}
  driver_04_update_install: ["curtin", "in-target", "--", "apt-get", "update", "--quiet"]
  {{if driver['package']}}
  driver_05_install: ["curtin", "in-target", "--", "apt-get", "-y", "install", "{{driver['package']}}"]
  {{endif}}
  driver_06_depmod: ["curtin", "in-target", "--", "depmod"]
  driver_07_update_initramfs: ["curtin", "in-target", "--", "update-initramfs", "-u"]
{{endif}}
EOF