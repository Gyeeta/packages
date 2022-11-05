#!/bin/bash

if [[ ! -d ./pool || ! `ls ./pool/*.rpm 2> /dev/null | head -1` =~ \.rpm$ ]]; then
	echo -e "ERROR : RPM Release script being run from a dir where deploy .rpm files or directory structure not available : Please run from a proper dir\n\n"
	exit 1
fi	

set -e
set -x 

rpm --addsign ./pool/*.rpm

cd ./pool

if [ -d ./repodata ]; then
	rm -rf ./repodata/
fi

createrepo .

gpg --detach-sign --armor repodata/repomd.xml

echo -e "Created RPM Repo successfully...\n"

exit 0

