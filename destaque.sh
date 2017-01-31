#!/bin/bash
MYARRAY=("$@")
echo \| sed \\
for arg in ${MYARRAY[@]}
do
	echo "-e \"s/$arg/\x1b[41m$arg\x1b[0m/g\"" \\
done
