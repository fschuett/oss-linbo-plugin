#
# Spec file for oss-linbo-plugn
# Copyright (c) 2019 Frank Schütte <fschuett@gymhim.de> Hildesheim, Germany.  All rights reserved.
#
%if 0%{?sle_version} == 150100 && 0%{?is_opensuse}
%define osstype oss
%define SERVERDIR oss
%else
%define osstype cranix
%define SERVERDIR cranix
%endif
Name:		oss-linbo-plugin
Summary:	oss admin interface plugin for oss-linbo
Version:	2.3.63
Release:	0
License:	GPL-3.0-or-later
Vendor:		openSUSE Linux
Group:		System/Packages
Source:		%{name}-%{version}.tar.gz
BuildRequires:	unzip
Requires:	%{osstype}-base 
BuildRoot:    %{_tmppath}/%{name}-root
Requires:	oss-linbo >= %{version}

%description
The admin interface plugin for oss-linbo connects linbo base functionality 
to admin interface for oss (open school server) for releases from 4.0 on.

Authors:
--------
        see readme

%prep
%setup -D

%build
# nothing to do
%install
# install files and directories
mkdir -p %{buildroot}/usr/share/%SERVERDIR/plugins/add_device
mkdir -p %{buildroot}/usr/share/%SERVERDIR/plugins/modify_device
mkdir -p %{buildroot}/usr/share/%SERVERDIR/plugins/delete_device
install linbo-modify-dhcpd.pl %{buildroot}/usr/share/%SERVERDIR/plugins/modify_device/linbo-modify-dhcpd.pl
pushd %{buildroot}/usr/share/%SERVERDIR/plugins/add_device
ln -s ../modify_device/linbo-modify-dhcpd.pl linbo-add-dhcpd.pl
popd
pushd %{buildroot}/usr/share/%SERVERDIR/plugins/delete_device
ln -s ../modify_device/linbo-modify-dhcpd.pl linbo-delete-dhcpd.pl
popd
install linbo-modify-device.pl %{buildroot}/usr/share/%SERVERDIR/plugins/modify_device/linbo-modify-device.pl
install linbo-update-ips.pl %{buildroot}/usr/share/%SERVERDIR/plugins/add_device/linbo-update-ips.pl
install linbo-delete-device.pl %{buildroot}/usr/share/%SERVERDIR/plugins/delete_device/linbo-delete-device.pl

# mkdir -p %{buildroot}/usr/share/%SERVERDIR/plugins/add_hwconf
# mkdir -p %{buildroot}/usr/share/%SERVERDIR/plugins/modify_hwconf
# mkdir -p %{buildroot}/usr/share/%SERVERDIR/plugins/delete_hwconf
# install linbo-modify-hwconf.pl %{buildroot}/usr/share/%SERVERDIR/plugins/modify_hwconf/linbo-modify-hwconf.pl
# pushd %{buildroot}/usr/share/%SERVERDIR/plugins/add_hwconf
# ln -s ../modify_hwconf/linbo-modify-hwconf.pl linbo-add-hwconf.pl
# popd
# pushd %{buildroot}/usr/share/%SERVERDIR/plugins/delete_hwconf
# ln -s ../modify_hwconf/linbo-modify-hwconf.pl linbo-delete-hwconf.pl
# popd
mkdir -p %{buildroot}/usr/share/%SERVERDIR/plugins/shares/itool/open
install linbo-restore-vlan-links.sh %{buildroot}/usr/share/%SERVERDIR/plugins/shares/itool/open/linbo-restore-vlan-links.sh
mkdir -p %{buildroot}/etc/import-workstations.d
mkdir -p %{buildroot}/usr/sbin
install import_workstations %{buildroot}/usr/sbin/import_workstations
mkdir -p %{buildroot}/usr/share/linbo
install linbo_sync_hosts.pl %{buildroot}/usr/share/linbo/linbo_sync_hosts.pl
install linbo_update_workstations.pl %{buildroot}/usr/share/linbo/linbo_update_workstations.pl
install linbo_write_dhcpd.pl %{buildroot}/usr/share/linbo/linbo_write_dhcpd.pl
install wimport.sh %{buildroot}/usr/share/linbo/wimport.sh

export NO_BRP_CHECK_RPATH=true


%files
%defattr(-,root,root)
%doc README.md LICENSE
%dir /etc/import-workstations.d
%dir /usr/share/linbo
/usr/share/linbo/*
%defattr(0755,root,root)
/usr/sbin/import_workstations
%dir /usr/share/%SERVERDIR
%dir /usr/share/%SERVERDIR/plugins
%dir /usr/share/%SERVERDIR/plugins/add_device
/usr/share/%SERVERDIR/plugins/add_device/linbo-update-ips.pl
/usr/share/%SERVERDIR/plugins/add_device/linbo-add-dhcpd.pl
%dir /usr/share/%SERVERDIR/plugins/modify_device
/usr/share/%SERVERDIR/plugins/modify_device/linbo-modify-device.pl
/usr/share/%SERVERDIR/plugins/modify_device/linbo-modify-dhcpd.pl
%dir /usr/share/%SERVERDIR/plugins/delete_device
/usr/share/%SERVERDIR/plugins/delete_device/linbo-delete-device.pl
/usr/share/%SERVERDIR/plugins/delete_device/linbo-delete-dhcpd.pl
# %dir /usr/share/%SERVERDIR/plugins/add_hwconf
# /usr/share/%SERVERDIR/plugins/add_hwconf/linbo-add-hwconf.pl
# %dir /usr/share/%SERVERDIR/plugins/modify_hwconf
# /usr/share/%SERVERDIR/plugins/modify_hwconf/linbo-modify-hwconf.pl
# %dir /usr/share/%SERVERDIR/plugins/delete_hwconf
# /usr/share/%SERVERDIR/plugins/delete_hwconf/linbo-delete-hwconf.pl
%dir /usr/share/%SERVERDIR/plugins/shares
%dir /usr/share/%SERVERDIR/plugins/shares/itool
%dir /usr/share/%SERVERDIR/plugins/shares/itool/open
/usr/share/%SERVERDIR/plugins/shares/itool/open/linbo-restore-vlan-links.sh

%changelog
