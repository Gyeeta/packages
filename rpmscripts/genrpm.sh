#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

shopt -s dotglob

if [ $# -lt 3 ]; then
	echo -e "\nUsage : $0 <package name> <Version> <Install Source files base dir>\n"
	echo -e "For e.g. : ./genrpm.sh partha 0.1.1 /installs \n"
	exit 1
fi

VERSION=$2
BASEINSTALLDIR=$3

if [ ! -d "./${1}" ]; then
	echo -e "\nERROR : Package Name specified as "$1" but ./"$1" dir not found\n\n"
	exit 1
fi	

if [ ! -d $BASEINSTALLDIR/$1/ ]; then
	echo -e "\nERROR : Install Files dir specified as $BASEINSTALLDIR but $BASEINSTALLDIR/$1 is not a dir\n\n"
	exit 1
fi	

if [ ! -f ../.pgpkeys/pgp-key.private ]; then
	echo -e "\nERROR : GPG Private Key ../.pgpkeys/pgp-key.private not found\n\n"
	exit 1
fi	

set -x

INITDIR=$PWD
APPNAME=$1

PKGNAME=gyeeta-${APPNAME}
DESTDIR="${PWD}/../pkg/rpm-repo/pool"

APP_SCRIPTS_DIR=${INITDIR}/${APPNAME}

export APP_FILES_DIR=$( cd $BASEINSTALLDIR/$1/ 2> /dev/null && pwd || ( echo -n ./Invalid_Files_Dir_Specified ) )

set -e

gpg --import $INITDIR/../.pgpkeys/pgp-key.private

if [ `grep -c 4D491C04929C6424 ~/.rpmmacros 2> /dev/null` -ne 1 ]; then
	echo -e "\n%_signature gpg\n%_gpg_name 4D491C04929C6424" >> ~/.rpmmacros
fi	

rm -rf ~/rpmbuild || :

mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

cp $APP_SCRIPTS_DIR/*.spec ~/rpmbuild/SPECS/

sed -i "s/Version:.*$/Version: $VERSION/g" ~/rpmbuild/SPECS/*.spec


cp $APP_SCRIPTS_DIR/* ~/rpmbuild/SOURCES/
rm ~/rpmbuild/SOURCES/*.spec

cd $APP_FILES_DIR/..

tar czf ~/rpmbuild/SOURCES/${APPNAME}.tar.gz ./$APPNAME/

rpmbuild -bb ~/rpmbuild/SPECS/*.spec

if [ ! -f ~/rpmbuild/RPMS/$(uname -m)/${PKGNAME}-*.rpm ]; then
	echo -e "ERROR : Failed to create $PKGNAME rpm...\n"
	exit 1
fi

cp ~/rpmbuild/RPMS/$(uname -m)/${PKGNAME}-*.rpm $DESTDIR/

set +e

chown `stat --format="%u:%g" $DESTDIR/` ${DESTDIR}/*.rpm 2> /dev/null

echo -e "Created rpm ${DESTDIR}/${PKGNAME}-*.rpm successfully\n"

exit 0

