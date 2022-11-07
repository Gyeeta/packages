#!/bin/bash

set -ex

for i in `ls install*.sh`;do 
	sha256sum $i > $i.sum
done	

