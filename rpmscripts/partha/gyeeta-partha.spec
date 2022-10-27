
%define _name gyeeta-partha

%{?rhel:%global centos_ver %rhel}

Name: %{_name}
Version: 0.1.0
Release: 1
Summary: Partha - Gyeeta's Host Monitor Agent
License: GPLv3+
URL: https://github.com/gyeeta/gyeeta
Packager: Gyeeta (https://github.com/gyeeta)
Requires: kernel >= 4.4, kernel-devel, /usr/sbin/useradd, sudo, /usr/sbin/setcap
Source0: partha.tar.gz
Source1: gyeeta-partha.service
Source2: LICENSE
BuildArch: x86_64

%if 0%{?centos_ver} && 0%{?centos_ver} < 9
Requires: libnsl
%endif

BuildRequires: systemd-rpm-macros

# Skip Library Dependency detection
AutoReqProv: no

%global debug_package %{nil}

%description
Gyeeta is an Observability Product monitoring Services, Processes and Hosts. Partha is the Host Monitor Agent of Gyeeta.

%prep

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}/opt/gyeeta/
cd %{buildroot}/opt/gyeeta/
tar -xzf %{S:0}

mkdir -p %{buildroot}%{_unitdir}
cp %{S:1} %{buildroot}%{_unitdir}

mkdir -p %{buildroot}/usr/share/doc/%{_name}
cp %{S:2} %{buildroot}/usr/share/doc/%{_name}

%clean
rm -rf %{buildroot}

%pre
if ! getent group gyeeta > /dev/null; then
	/usr/sbin/groupadd --system gyeeta
fi

if ! getent passwd gyeeta > /dev/null; then
	/usr/sbin/useradd --system -g gyeeta --home-dir /opt/gyeeta --no-create-home gyeeta
fi

%post

chown -h gyeeta:gyeeta /opt/gyeeta 2> /dev/null || :

chown -hR gyeeta:gyeeta /opt/gyeeta/partha

/usr/sbin/setcap cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_ipc_lock,cap_kill,cap_mac_admin,cap_mknod,cap_sys_chroot,cap_sys_resource,cap_setpcap,cap_sys_ptrace,cap_sys_admin,cap_net_admin,cap_net_raw,cap_sys_module+ep /opt/gyeeta/partha/partha
if [ $? -ne 0 ]; then
	echo -e "\nERROR : Failed to set Capabilities to partha binary. partha will not start unless run as root...\n"
fi	

%preun
if [ $1 = 0 ]; then
	/usr/bin/systemctl disable gyeeta-partha
fi

%postun
if [ $1 -ge 1 ]; then
	/usr/bin/systemctl restart gyeeta-partha >/dev/null 2>&1 || :
fi


%files

%license /usr/share/doc/%{_name}/LICENSE
%{_unitdir}/%{_name}.service

%defattr(-,gyeeta,gyeeta,-)
%dir /opt/gyeeta/partha
/opt/gyeeta/partha/

%changelog
* Wed Oct 26 2022 Gyeeta <gyeetainc@gmail.com>
- Initial Release


