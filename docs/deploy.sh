#!/bin/bash -x

git checkout gh-pages && git rebase main && git push origin gh-pages && git checkout main

if [ $? = 0 ]; then
	echo -e "\nSuccessfully deployed to gh-pages branch..\n\n"
	exit 0
else
	echo -e "ERROR : Failed to update gh-pages branch\n"
	exit 1
fi	
