#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

HOSTNAME=$( hostname )

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

check_apt()
{
	if ! command -v apt-get > /dev/null; then
		echo -e "Debian/Ubuntu Based OS detected but apt-get command not found. Exiting installation...\n"
		exit 1
	fi	

	if ! command -v sudo > /dev/null; then
		echo "* Installing sudo"
		apt-get -qq -y install sudo < /dev/null
		check_cmd "sudo install"
	fi

	if ! command -v curl > /dev/null; then
		echo "* Installing curl"
		apt-get -qq -y install curl < /dev/null
		check_cmd "curl install"
	fi
}	

check_rpm()
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
		$YUMCMD -q -y install sudo
		check_cmd "sudo install"
	fi

	if ! command -v curl > /dev/null; then
		echo "* Installing curl"
		$YUMCMD -q -y install curl
		check_cmd "curl install"
	fi

}	

check_zypper()
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

}	

check_hostname()
{
	if [[ $HOSTNAME =~ localhost* ]]; then
		echo -e "\nPlease set the hostname to a valid hostname (not based on localhost). Exiting installation...\n"
		exit 1
	fi
}

check_processor

check_linux_kernel_version

check_hostname

if [ $(id -u) -ne 0 ]; then
	echo -e "\nInstall script must be run as root. Exiting without installing...\n"
	exit 1
fi

if [ ! -f /etc/os-release ]; then
	echo -e "/etc/os-release file not found. Install cannot proceed. Please contact Gyeeta at https://github.com/gyeeta/packages for help with a manual install...\n"
	exit 1
fi	

DISTNAME=$( cat /etc/os-release | egrep "^NAME=|^PRETTY_NAME=" | tail -1 | awk -F\" '{print $2}' )
ID_LIKE=$( cat /etc/os-release | grep "^ID_LIKE=" 2> /dev/null | awk -F\= '{print $2}' )

if [[ $DISTNAME =~ Ubuntu* || $DISTNAME =~ Debian* || $ID_LIKE =~ debian ]]; then
	check_apt

elif [[ $DISTNAME =~ Amazon* || $DISTNAME =~ CentOS* || $DISTNAME =~ "Red Hat Enterprise"* || $DISTNAME =~ "Oracle Linux"* || $DISTNAME =~ "Scientific Linux"* || $DISTNAME =~ Fedora* || $DISTNAME =~ Rocky* || $ID_LIKE =~ *rhel* ]]; then
	check_rpm

elif [[ $DISTNAME =~ SUSE* || $DISTNAME =~ openSUSE* ]]; then	
	check_zypper
	
else
	echo -e "Unsupported Linux Distribution detected... Cannot install packages. Please contact Gyeeta at https://github.com/gyeeta/packages for help with a manual install...\n"
	exit 1
fi

if [ $# -lt 3 ]; then
	echo -e "\nUsage : $0 <DB Data directory path> <DB postgres user Password> <WebUI admin user Password>\n\n"
	echo -e "For example, $0 /opt/gyeeta/postgresdb/data dbPassword adminPassword\n"

	exit 1
fi	

DBDIR=$1
DBPASS=$2
UIPASS=$3

echo -e "\n* Starting installation of Gyeeta PostgresDB with DB data dir set to $DBDIR \n"
sleep 3

curl -o /tmp/install-gyeeta-postgresdb.sh -s https://gyeeta.io/packages/install-gyeeta-postgresdb.sh
check_cmd "curl Postgres Install script"

sudo bash /tmp/install-gyeeta-postgresdb.sh $DBDIR $DBPASS 10040
check_cmd "Postgres Installation"

if [ -z "$( sudo -H -u gyeeta /opt/gyeeta/postgresdb/rundb.sh printpids )" ]; then
	echo -e "\nERROR : Postgres DB not currently running. Exiting the installation...\n"
	exit 1
fi

echo -e "\nPostgres DB installed successfully...\n\n* Starting installation of Shyama Central Server\n"
sleep 3

cat << EOF > /tmp/.gyeeta-shyama1.json
{
        "listener_ip"           :   "0.0.0.0",
        "listener_port"         :   10037,
        "service_hostname"      :   "$HOSTNAME",
        "service_port"          :   10037,

        "shyama_name"           :   "shyama1",
        "shyama_secret"         :   "This is a secret",

        "min_madhava"           :   1,
        
        "postgres_hostname"     :   "$HOSTNAME",
        "postgres_port"         :   10040,
        "postgres_user"         :   "postgres",
        "postgres_password"     :   "$DBPASS",
        "postgres_storage_days" :   3,

        "webserver_url"         :   "http://${HOSTNAME}:10039"	
}
EOF

check_cmd "Creating Shyama config"

curl -o /tmp/install-gyeeta-shyama.sh -s https://gyeeta.io/packages/install-gyeeta-shyama.sh
check_cmd "curl Shyama Install script"

sudo bash /tmp/install-gyeeta-shyama.sh /tmp/.gyeeta-shyama1.json
check_cmd "Shyama Installation"

rm -f /tmp/.gyeeta-shyama1.json 2> /dev/null

if [ -z "$( sudo -H -u gyeeta /opt/gyeeta/shyama/runshyama.sh printpids )" ]; then
	echo -e "\nERROR : Shyama server not currently running. Exiting the installation...\n"
	exit 1
fi


echo -e "\nShyama Central Server installed successfully...\n\n* Starting installation of Madhava Intermediate Server\n"
sleep 3

cat << EOF > /tmp/.gyeeta-madhava1.json
{
        "listener_ip"           :   "0.0.0.0",
        "listener_port"         :   10038,
        "madhava_name"          :   "madhava1",
        "service_hostname"      :   "$HOSTNAME",
        "service_port"          :   10038,

        "shyama_hosts"          :   [ "$HOSTNAME" ],
        "shyama_ports"          :   [ 10037 ],
        "shyama_secret"         :   "This is a secret",
        
        "postgres_hostname"     :   "$HOSTNAME",
        "postgres_port"         :   10040,
        "postgres_user"         :   "postgres",
        "postgres_password"     :   "$DBPASS",
        "postgres_storage_days" :   3
}
EOF

check_cmd "Creating Madhava config"

curl -o /tmp/install-gyeeta-madhava.sh -s https://gyeeta.io/packages/install-gyeeta-madhava.sh
check_cmd "curl Madhava Install script"

sudo bash /tmp/install-gyeeta-madhava.sh /tmp/.gyeeta-madhava1.json
check_cmd "Madhava Installation"

rm -f /tmp/.gyeeta-madhava1.json 2> /dev/null

if [ -z "$( sudo -H -u gyeeta /opt/gyeeta/madhava/runmadhava.sh printpids )" ]; then
	echo -e "\nERROR : Madhava server not currently running. Exiting the installation...\n"
	exit 1
fi


echo -e "\nMadhava Intermediate Server installed successfully...\n\n* Starting installation of Node Webserver...\n"
sleep 3

cat << EOF > /tmp/.gyeeta-nodewebserver1.env

CFG_SHYAMA_HOSTS='[ "$HOSTNAME" ]'
CFG_SHYAMA_PORTS='[ 10037 ]'

CFG_LISTENER_IP='0.0.0.0'
CFG_LISTENER_PORT=10039

CFG_AUTHTYPE='basic'
CFG_ADMINPASSWORD='$UIPASS'

CFG_TOKENEXPIRY='1d'
CFG_JWTSECRET='SecretPassForCookie'

CFG_USEHTTP=true

EOF

check_cmd "Creating Node Webserver config"

curl -o /tmp/install-gyeeta-nodewebserver.sh -s https://gyeeta.io/packages/install-gyeeta-nodewebserver.sh
check_cmd "curl Node Webserver Install script"

sudo bash /tmp/install-gyeeta-nodewebserver.sh /tmp/.gyeeta-nodewebserver1.env
check_cmd "Node Webserver Installation"

rm -f /tmp/.gyeeta-nodewebserver1.env 2> /dev/null

if [ -z "$( sudo /opt/gyeeta/nodewebserver/runwebserver.sh printpids )" ]; then
	echo -e "\nERROR : Node Webserver server not currently running. Exiting the installation...\n"
	exit 1
fi


echo -e "\nNode Webserver installed successfully...\n\n* Starting installation of Alert Agent...\n"
sleep 3

cat << EOF > /tmp/.gyeeta-alertaction1.env

CFG_SHYAMA_HOSTS='[ "$HOSTNAME" ]'
CFG_SHYAMA_PORTS='[ 10037 ]'

EOF

check_cmd "Creating Alert Agent config"

curl -o /tmp/install-gyeeta-alertaction.sh -s https://gyeeta.io/packages/install-gyeeta-alertaction.sh
check_cmd "curl Node Webserver Install script"

sudo bash /tmp/install-gyeeta-alertaction.sh /tmp/.gyeeta-alertaction1.env
check_cmd "Alert Agent Installation"

rm -f /tmp/.gyeeta-alertaction1.env 2> /dev/null

if [ -z "$( sudo /opt/gyeeta/alertaction/runalertaction.sh printpids )" ]; then
	echo -e "\nERROR : Alert Agent not currently running. Exiting the installation...\n"
	exit 1
fi


cat << EOF > /tmp/partha_main_$$.json
{
	"cluster_name"          :   "cluster1",
        "shyama_hosts"          :   [ "$HOSTNAME" ],
        "shyama_ports"          :   [ 10037 ],
	"is_kubernetes"         :   true
}
EOF

check_cmd "Creating sample Partha config"

echo -e "\n\nSuccessfully installed all Gyeeta Server Components and Alert Agent.\n\n"
echo -e "A sample Partha config has also been created at /tmp/partha_main_$$.json\n\n"
echo -e "Please copy this sample config file to all hosts that need to be monitored to say /tmp dir. Then run the following command to install Partha Host Agent...\n"
echo "curl -o /tmp/install-gyeeta-partha.sh -s https://gyeeta.io/packages/install-gyeeta-partha.sh && sudo bash /tmp/install-gyeeta-partha.sh /tmp/partha_main_$$.json"
echo -e "\n\nAfter installing Partha Agents, the Web UI can be accessed by pointing your Web Browser to URL : http://$HOSTNAME:10039 using user as admin and Password as $UIPASS\n\n"

echo -e "Exiting after successful Gyeeta Server components installation...\n"

exit 0

