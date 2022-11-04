#!/bin/bash

if [[ ! -d ./pool/main || ! -d ./dists/stable/main/binary-amd64 || ! `ls ./pool/main/*.deb 2> /dev/null | head -1` =~ \.deb$ ]]; then
	echo -e "ERROR : Debian Release script being run from a dir where deploy .deb files or directory structure not available : Please run from a proper dir\n\n"
	exit 1
fi	

set -e
set -x 

export GNUPGHOME=${PWD}/../../.pgpkeys

if [ ! -d $GNUPGHOME ]; then
	echo -e "ERROR : Missing GPG Key directory $GNUPGHOME : Please ensure this dir is available first...\n\n"
	exit 1
fi	

if [ `gpg --list-keys 2> /dev/null | grep -cw Gyeeta` -eq 0 ]; then
	echo -e "ERROR : Could not find the Gyeeta PGP Key in GPG Key directory $GNUPGHOME : Please ensure this key is available first...\n\n"
	exit 1
fi	

find pool/ -name \*.deb -exec apt-ftparchive packages {} \; > dists/stable/main/binary-amd64/Packages


gzip -c dists/stable/main/binary-amd64/Packages > dists/stable/main/binary-amd64/Packages.gz
bzip2 -z -c dists/stable/main/binary-amd64/Packages > dists/stable/main/binary-amd64/Packages.bz2

apt-ftparchive release -o APT::FTPArchive::Release::Origin=Gyeeta -o APT::FTPArchive::Release::Label=Gyeeta \
			-o APT::FTPArchive::Release::Suite=stable -o APT::FTPArchive::Release::Codename=stable \
			-o APT::FTPArchive::Release::Components=main -o APT::FTPArchive::Release::Architectures=amd64 \
			-o APT::FTPArchive::Release::Description="Gyeeta Debian Package Repository" dists/stable > dists/stable/Release

cat ./dists/stable/Release | gpg --default-key Gyeeta -abs > ./dists/stable/Release.gpg

cat ./dists/stable/Release | gpg --default-key Gyeeta --clearsign -abs > ./dists/stable/InRelease

