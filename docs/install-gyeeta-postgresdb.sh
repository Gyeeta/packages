#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

check_processor()
{
	if [ "$( uname -m )" != "x86_64" ]; then
		echo -e "\nInstall supported only for x86_64 processors. Exiting without installing...\n"
		exit 1
	fi

	PROCINFO=$( cat /proc/cpuinfo )

	if [ $( echo "$PROCINFO" | grep -w flags | grep -ic avx ) -eq 0 ]; then
		echo -e "\nInstall can run on hosts with processors having avx instruction support (Intel Sandybridge (2012) or above).\n\nYour processor seems to be a very old one. Please install on a machine with a newer processor.\n\nExiting ...\n\n"
		exit 1
	fi
}

check_processor

if [ $(id -u) -ne 0 ]; then
	echo -e "\nInstall script must be run as root. Exiting without installing...\n"
	exit 1
fi



