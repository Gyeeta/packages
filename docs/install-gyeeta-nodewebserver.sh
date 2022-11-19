#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

export PKGNAME=gyeeta-nodewebserver
export INSTALLDIR=/opt/gyeeta/nodewebserver

check_processor()
{
	if [ "$( uname -m )" != "x86_64" ]; then
		echo -e "\nInstall supported only for x86_64 (Intel / AMD 64 bit) processors. Exiting without installing...\n"
		exit 1
	fi

	PROCINFO=$( cat /proc/cpuinfo )

	if [ $( echo "$PROCINFO" | grep -w flags | grep -ic avx ) -eq 0 ]; then
		echo -e "\nInstall can be run only on hosts with processors having avx instruction support (Intel Sandybridge (2012) or above).\n\nYour host processor seems to be a very old one. Please install on a host with a newer processor.\n\nExiting ...\n\n"
		exit 1
	fi
}

check_linux_kernel_version()
{
	KERN_VER=`uname -r`

	KERN_NUM1=$( echo $KERN_VER | awk -F. '{print $1}' )
	KERN_NUM2=$( echo $KERN_VER | awk -F. '{print $2}' )
	KERN_NUM3=$( echo $KERN_VER | awk -F. '{print $3}' | awk -F- '{print $1}' )

	MIN_VER="4.4.0"

	if [ $KERN_NUM1 -lt 4 ]; then
		echo -e "Linux Kernel version $KERN_NUM1 is less than minimum $MIN_VER required for package. Exiting...\n\n"
		exit 1
	elif [ $KERN_NUM1 -eq 4 ] && [ $KERN_NUM2 -lt 4 ]; then
		echo -e "Linux Kernel version $KERN_NUM1 is less than minimum $MIN_VER required for package. Exiting...\n\n"
		exit 1
	fi
}


check_cmd()
{
	if [ $? -ne 0 ]; then
		echo -e "\nERROR : Failed to execute ${1:-"last"} command : Exiting installation...\n"
		exit 1
	fi	
}	

install_apt()
{
	export DEBIAN_FRONTEND=noninteractive
	
	if ! command -v apt-get > /dev/null; then
		echo -e "Debian/Ubuntu Based OS detected but apt-get command not found. Exiting installation...\n"
		exit 1
	fi	

	if ! command -v sudo > /dev/null; then
		echo "* Installing sudo"
		apt-get -qq update < /dev/null
		apt-get -qq -y install sudo < /dev/null
		check_cmd "sudo install"
	fi

	if ! command -v curl > /dev/null; then
		echo "* Installing curl"
		apt-get -qq update < /dev/null
		apt-get -qq -y install curl < /dev/null
		check_cmd "curl install"
	fi

	if ! command -v gpg > /dev/null; then
		echo "* Installing gpg"
		apt-get -qq update < /dev/null
		apt-get -qq -y install gpg < /dev/null
		check_cmd "gpg install"
	fi

	curl https://pkg.gyeeta.workers.dev/pgp-key.public | sudo gpg --yes --dearmor --output /usr/share/keyrings/gyeeta-keyring.gpg
	check_cmd "GPG Key Import"

	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/gyeeta-keyring.gpg] https://pkg.gyeeta.workers.dev/apt-repo stable main" | sudo tee /etc/apt/sources.list.d/gyeeta.list
	check_cmd "Gyeeta Repo Add"

	apt-get -qq update < /dev/null

	apt-get -qq -y install $PKGNAME
	check_cmd "$PKGNAME package install"

}	

install_rpm()
{
	if command -v yum > /dev/null; then
		YUMCMD=yum
	elif command -v dnf > /dev/null; then
		YUMCMD=dnf
	else 
		echo -e "RHEL/Fedora RPM Based OS detected but yum or dnf commands not found. Exiting installation...\n"
		exit 1
	fi	

	if ! command -v sudo > /dev/null; then
		echo "* Installing sudo"
		$YUMCMD -y update
		$YUMCMD -q -y install sudo
		check_cmd "sudo install"
	fi

	if ! command -v curl > /dev/null; then
		echo "* Installing curl"
		$YUMCMD -y update
		$YUMCMD -q -y install curl
		check_cmd "curl install"
	fi

	rpm --import https://pkg.gyeeta.workers.dev/pgp-key.public
	check_cmd "RPM Key Import"

	curl -s -o /etc/yum.repos.d/gyeeta.repo https://pkg.gyeeta.workers.dev/rpm-repo/gyeeta.repo
	check_cmd "Gyeeta Repo Add"

	$YUMCMD -y update
	
	$YUMCMD install -y $PKGNAME
	check_cmd "$PKGNAME package install"
}	

install_zypper()
{
	if ! command -v zypper > /dev/null; then
		echo -e "SuSE Linux Based OS detected but zypper command not found. Exiting installation...\n"
		exit 1
	fi	

	if ! command -v sudo > /dev/null; then
		echo "* Installing sudo"
		zypper -q -n install sudo
		check_cmd "sudo install"
	fi

	if ! command -v curl > /dev/null; then
		echo "* Installing curl"
		zypper -q -n install curl
		check_cmd "curl install"
	fi

	rpm --import https://pkg.gyeeta.workers.dev/pgp-key.public
	check_cmd "RPM Key Import"

	curl -s -o /etc/zypp/repos.d/gyeeta.repo https://pkg.gyeeta.workers.dev/rpm-repo/gyeeta.repo
	check_cmd "Gyeeta Repo Add"

	zypper -q -n install $PKGNAME
	check_cmd "$PKGNAME package install"
}	


check_processor

check_linux_kernel_version

if [ $(id -u) -ne 0 ]; then
	echo -e "\nInstall script must be run as root. Exiting without installing...\n"
	exit 1
fi

if [ -f ${INSTALLDIR}/runwebserver.sh ]; then
	echo -e "\n$PKGNAME seems to be already installed at ${INSTALLDIR} : Please uninstall the older package if a fresh install is needed...\n"
	exit 1
fi

if [ $# -lt 1 ]; then
	echo -e "\nUsage : $0 <nodewebserver Config file>\n\nPlease check https://gyeeta.io/docs/installation/nodewebserver_config for reference\n\n"
	exit 1
fi	

export CFGFILE=$1

if [ ! -f $CFGFILE ]; then
	echo -e "\nERROR : nodewebserver Config file $CFGFILE not found...\n\nUsage : $0 <nodewebserver Config file>\n\nPlease check https://gyeeta.io/docs/installation/nodewebserver_config for reference\n\n"
	exit 1
elif [ $( egrep -c "CFG_SHYAMA_HOSTS|CFG_SHYAMA_PORTS|CFG_ADMINPASSWORD|CFG_USERPASSFILE" $CFGFILE 2> /dev/null ) -lt 3 ]; then	
	echo -e "\nERROR : nodewebserver Config file missing mandatory config params.\n\nPlease check https://gyeeta.io/docs/installation/nodewebserver_config for reference\n\n"
	exit 1
fi	

echo -e "\n* Starting installation of $PKGNAME package...\n"

if [ ! -f /etc/os-release ]; then
	echo -e "/etc/os-release file not found. Install cannot proceed. Please contact Gyeeta at https://github.com/gyeeta/packages for help with a manual install...\n"
	exit 1
fi	

DISTNAME=$( cat /etc/os-release | egrep "^NAME=|^PRETTY_NAME=" | tail -1 | awk -F\" '{print $2}' )
ID_LIKE=$( cat /etc/os-release | grep "^ID_LIKE=" 2> /dev/null | awk -F\= '{print $2}' )

if [[ $DISTNAME =~ Ubuntu* || $DISTNAME =~ Debian* || $ID_LIKE =~ debian ]]; then
	echo "Debian based OS detected..."
	
	PKGOS=apt
	install_apt

elif [[ $DISTNAME =~ Amazon* || $DISTNAME =~ CentOS* || $DISTNAME =~ "Red Hat Enterprise"* || $DISTNAME =~ "Oracle Linux"* || $DISTNAME =~ "Scientific Linux"* || $DISTNAME =~ Fedora* || $DISTNAME =~ Rocky* || $ID_LIKE =~ *rhel* ]]; then
	echo "RedHat / Amazon Linux based OS detected..."
	
	PKGOS=rpm
	install_rpm

elif [[ $DISTNAME =~ SUSE* || $DISTNAME =~ openSUSE* ]]; then	
	echo "SuSE Linux based OS detected..."
	
	PKGOS=zypper
	install_zypper
	
else
	echo -e "Unsupported Linux Distribution detected... Cannot install package. Please contact Gyeeta at https://github.com/gyeeta/packages for help with a manual install...\n"
	exit 1
fi

echo -e "\nInstalled $PKGNAME successfully. Now starting configuration...\n"

if [ $1 != "$INSTALLDIR/.env" ]; then
	cp -f $CFGFILE $INSTALLDIR/.env
	check_cmd "Config file copy"
fi

command -v systemctl > /dev/null
if [ $? -ne 0 ]; then
	echo -e "\nSystemD systemctl command not found. $PKGNAME will not auto-start after reboot. Please run the command on reboot to start : sudo -H -u gyeeta $INSTALLDIR/runwebserver.sh start\n"

	sudo -H -u gyeeta $INSTALLDIR/runwebserver.sh start < /dev/null
	check_cmd "Starting $PKGNAME ...\n\n"

	sleep 5
else
	systemctl -q start $PKGNAME
	systemctl -q enable $PKGNAME

	sleep 5

	if [ -n "$( sudo $INSTALLDIR/runwebserver.sh printpids )" ]; then
		echo -e "\n$PKGNAME is running. You can check its status using command : systemctl status $PKGNAME\n"
	fi	
fi

if [ -n "$( sudo $INSTALLDIR/runwebserver.sh printpids )" ]; then
	echo -e "\nSuccessfully installed and configured $PKGNAME\n\n"
else
	echo -e "\n$PKGNAME has been installed but is currently not running. Please check the logs or contact Gyeeta on Github...\n\n"
fi

exit 0

