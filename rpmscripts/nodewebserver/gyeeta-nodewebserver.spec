
%define _name gyeeta-nodewebserver


%undefine __brp_mangle_shebangs

Name: %{_name}
Version: 0.1.0
Release: 1
Summary: Nodewebserver - Gyeeta's Webserver
License: GPLv3+
URL: https://github.com/gyeeta/nodewebserver
Packager: Gyeeta (https://github.com/gyeeta)
Requires: /usr/sbin/useradd, sudo, /usr/sbin/setcap
Source0: nodewebserver.tar.gz
Source1: gyeeta-nodewebserver.service
Source2: LICENSE
BuildArch: x86_64

BuildRequires: systemd-rpm-macros

# Skip Library Dependency detection
AutoReqProv: no

# Skip /usr/lib/.build-id/
%define _build_id_links none

%global debug_package %{nil}

%description
Gyeeta is an Observability product monitoring Services, Processes and Hosts. Nodewebserver is the Webserver Component of Gyeeta.

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
if [ ! -f /opt/gyeeta/nodewebserver/.env ]; then
	touch /opt/gyeeta/nodewebserver/.env
	chmod 0660 /opt/gyeeta/nodewebserver/.env
fi

chown -h gyeeta:gyeeta /opt/gyeeta 2> /dev/null || :

chown -hR gyeeta:gyeeta /opt/gyeeta/nodewebserver

setcap cap_net_bind_service+ep /opt/gyeeta/nodewebserver/node

%preun
if [ $1 = 0 ]; then
	/usr/bin/systemctl disable gyeeta-nodewebserver
fi

%postun
if [ $1 -ge 1 ]; then
	/usr/bin/systemctl restart gyeeta-nodewebserver >/dev/null 2>&1 || :
fi


%files

%license /usr/share/doc/%{_name}/LICENSE
%{_unitdir}/%{_name}.service

%defattr(-,gyeeta,gyeeta,-)
%dir /opt/gyeeta/nodewebserver
/opt/gyeeta/nodewebserver/

%changelog
* Tue Jan 10 2023 Gyeeta <gyeetainc@gmail.com>
- Added BPF CO-RE Support and additional Host metrics

* Wed Oct 26 2022 Gyeeta <gyeetainc@gmail.com>
- Initial Release


