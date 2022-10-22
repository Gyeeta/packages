#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

shopt -s dotglob

if [ $# -lt 5 ]; then
	echo -e "\nUsage : $0 <package name> <install files dir> <pkg dest dir> <Version> <Changelog>\n"
	echo -e "For e.g. : ./gendeb.sh partha /tmp/installs/partha/  ../pkg/apt-repo/pool/main/ 0.1.0 \"Initial Release\"\n"
	exit 1
fi

if [ ! -d "./${1}" ]; then
	echo -e "\nERROR : Package Name specified as "$1" but ./"$1" dir not found\n\n"
	exit 1
fi	

if [ ! -d "$2" ]; then
	echo -e "\nERROR : Install Files dir specified as "$2" but is not a dir\n\n"
	exit 1
fi	

if [ ! -d "$3" ]; then
	echo -e "\nERROR : Package Destination dir specified as "$3" but is not a dir\n\n"
	exit 1
fi	

INITDIR=$PWD
APPNAME=$1
PKGNAME=gyeeta-${APPNAME}
DESTDIR=$3
VERSION=$4
CHANGELOG=$5

APP_SCRIPTS_DIR=${INITDIR}/${APPNAME}
APP_FILES_DIR=$( cd "$2" 2> /dev/null && pwd || ( echo -n ./Invalid_Files_Dir_Specified ) )
CACHEDIR=${PWD}/cache/${PKGNAME}_${VERSION}_amd64

rm -Rf $CACHEDIR 2> /dev/null
mkdir -m 0775 -p $CACHEDIR/{DEBIAN,opt/gyeeta/${APPNAME},lib/systemd/system,usr/share/doc/$PKGNAME}

if [ ! -d $CACHEDIR ]; then
	echo -e "\nERROR : Could not create Cache dir $CACHEDIR\n"
	exit 1
fi	

set -e

sed -i "s/Version:.*$/Version: $VERSION/g" ./${APPNAME}/meta/control

cp -a ./${APPNAME}/meta/* ${CACHEDIR}/DEBIAN/

echo "9" > ${CACHEDIR}/DEBIAN/compat

cp -p ./${APPNAME}/systemd/* ${CACHEDIR}/lib/systemd/system/

if [ `grep -c ${VERSION} ./${APPNAME}/usrdoc/changelog` -eq 0 ]; then
	echo -e "${PKGNAME} (${VERSION}) stable; urgency=low\n\n  * ${CHANGELOG}\n\n -- Gyeeta <gyeetainc@gmail.com> $( date -R )\n" > ./${APPNAME}/usrdoc/changelog__
	cat ./${APPNAME}/usrdoc/changelog >> ./${APPNAME}/usrdoc/changelog__
	mv ./${APPNAME}/usrdoc/changelog__ ./${APPNAME}/usrdoc/changelog
fi

cp -p ./${APPNAME}/usrdoc/* ${CACHEDIR}/usr/share/doc/$PKGNAME/

gzip -c ${CACHEDIR}/usr/share/doc/$PKGNAME/changelog > ${CACHEDIR}/usr/share/doc/$PKGNAME/changelog.Debian.gz

rm ${CACHEDIR}/usr/share/doc/$PKGNAME/changelog

set +e 

cd $CACHEDIR

cp -a $APP_FILES_DIR/* ./opt/gyeeta/${APPNAME}/

if [ $? -ne 0 ]; then
	echo -e "\nERROR : Failed to copy Package files from $APP_FILES_DIR/* to ./opt/gyeeta/${APPNAME}/\n"
	exit 1
fi	

# Generate md5sums
md5sum $(find * -type f -not -path 'DEBIAN/*') > DEBIAN/md5sums

if [ $? -ne 0 ]; then
	echo -e "\nERROR : Failed to generate md5sums file...\n\n"
	exit 1
fi

cd ${CACHEDIR}/..

dpkg-deb --root-owner-group --build ${PKGNAME}_${VERSION}_amd64

if [ $? -ne 0 ]; then
	echo -e "\nERROR : Failed to generate debian package...\n\n"
	exit 1
fi

cd $INITDIR

mv ./cache/${PKGNAME}_${VERSION}_amd64.deb $DESTDIR/

if [ $? -ne 0 ]; then
	echo -e "\nERROR : Failed to move debian package to $DESTDIR\n\n"
	exit 1
fi

exit 0

