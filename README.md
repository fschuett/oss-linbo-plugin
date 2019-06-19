# oss-linbo-plugin
oss admin interface plugin for oss-linbo
Copyright Frank Schütte <fschuett@gymhim.de> 2019

description
===========
The admin interface plugin for oss-linbo connects linbo base functionality to admin interface for oss (open school server) for releases from 4.0 on.

import_workstations
===================
Main script to import linbo data into oss admin database. It iterates over all hosts and updates any entries.

import_workstations helper scripts:
-----------------------------------
linbo-update-ips.pl, linbo_sync_hosts.pl, linbo_update_workstations.pl, wimport.sh are helper scripts, called from import_workstations.

restore-vlan-links.sh
=====================
Restore links in pxelinux.cfg directory to vlan start menu.


plugins
=======
OSS calls scripts for various events. For these events oss-linbo-plugin provides scripts to modify linbo entries.

linbo-*-device.pl
-----------------
Plugin scripts to execute on device add|modify|remove.

linbo-*-dhcpd.pl
----------------
Plugin scripts to execute con device add|modify|remove to update dhcpd data.

