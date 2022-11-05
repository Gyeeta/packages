#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

shopt -s dotglob

if [ $# -lt 3 ]; then
	echo -e "\nUsage : $0 <package name> <Install Source files base dir> <Changelog>\n"
	echo -e "For e.g. : ./gendeb.sh partha ../../../installs/ \"Initial Release\"\n"
	exit 1
fi

if [ ! -d "./${1}" ]; then
	echo -e "\nERROR : Package Name specified as "$1" but ./"$1" dir not found\n\n"
	exit 1
fi	

if [ ! -d "$2"/$1/ ]; then
	echo -e "\nERROR : Install Files dir specified as "$2" but "$2"/$1 is not a dir\n\n"
	exit 1
fi	

set -x

INITDIR=$PWD
APPNAME=$1
CHANGELOG="$3"

PKGNAME=gyeeta-${APPNAME}
DESTDIR="../pkg/apt-repo/pool/main/"


APP_SCRIPTS_DIR=${INITDIR}/${APPNAME}
export APP_FILES_DIR=$( cd "$2"/$1/ 2> /dev/null && pwd || ( echo -n ./Invalid_Files_Dir_Specified ) )

VERSION=$( $APP_FILES_DIR/run*.sh --version 2> /dev/null | awk '{ printf "%s", $NF }' )

if [ -z "$VERSION" ]; then
	echo -e "\nERROR : Could not detect Package $APPNAME Version\n"
	exit 1
fi	

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

set +x

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

set -x

cd ${CACHEDIR}/..

dpkg-deb --root-owner-group --build ${PKGNAME}_${VERSION}_amd64

if [ $? -ne 0 ]; then
	echo -e "\nERROR : Failed to generate debian package...\n\n"
	exit 1
fi

cd $INITDIR

rm -Rf $CACHEDIR

mv ./cache/${PKGNAME}_${VERSION}_amd64.deb $DESTDIR/

if [ $? -ne 0 ]; then
	echo -e "\nERROR : Failed to move debian package to $DESTDIR\n\n"
	exit 1
fi

exit 0

