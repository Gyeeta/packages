#!/bin/bash

if [[ ! -d ./pool || ! `ls ./pool/*.rpm 2> /dev/null | head -1` =~ \.rpm$ ]]; then
	echo -e "ERROR : RPM Release script being run from a dir where deploy .rpm files or directory structure not available : Please run from a proper dir\n\n"
	exit 1
fi	

if [ ! -f ../../.pgpkeys/pgp-key.private ]; then
	echo -e "\nERROR : GPG Private Key ../../.pgpkeys/pgp-key.private not found\n\n"
	exit 1
fi	

set -e
set -x 

gpg --import ../../.pgpkeys/pgp-key.private

if [ `grep -c 4D491C04929C6424 ~/.rpmmacros 2> /dev/null` -ne 1 ]; then
	echo -e "\n%_signature gpg\n%_gpg_name 4D491C04929C6424" >> ~/.rpmmacros
fi	

rpm --addsign ./pool/*.rpm

cd ./pool

if [ -d ./repodata ]; then
	rm -rf ./repodata/
fi

createrepo .

gpg --detach-sign --armor ./repodata/repomd.xml

set +e

chown -R `stat --format="%u:%g" ./` ./repodata/

echo -e "Created RPM Repo successfully...\n"

exit 0

