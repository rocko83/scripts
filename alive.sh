#!/bin/bash
function ajuda() {
	echo ajuda
}
function pingar() {
	ping -c 1 $1 > /dev/null
	retorno1=$?
	ping -c 1 $1 > /dev/null
	retorno2=$?
	if [ $retorno1 -eq 0 ] && [ $retorno2 -eq 0 ]
	then
		echo 0\;$1
	else
		echo 1\;$1
	fi
	
}
if [ $# -eq 0 ] 
then
	ajuda
else
	echo $* | \
	tr ' ' '\n' |\
	while read endereco
	do
		pingar $endereco
	done
fi
