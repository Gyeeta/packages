#!/bin/bash -x

docker run -it --rm --hostname rockylinux --name rocky -v `pwd`:/packages -v `pwd`/../../installs:/installs ghcr.io/gyeeta/rockydev:latest

