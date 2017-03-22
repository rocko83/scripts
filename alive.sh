#!/bin/bash -x
export RESULTADOS=()
export ITERACAO=1
function ajuda() {
	echo ajuda
}
function pingar() {
	ping -c 1 $1 2> /dev/null > /dev/null
	retorno1=$?
	ping -c 1 $1 2> /dev/null > /dev/null
	retorno2=$?
	if [ $retorno1 -eq 0 ] && [ $retorno2 -eq 0 ]
	then
		echo 0
	else
		echo 1
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
		RESULTADOS[$ITERACAO]=$(pingar $endereco):$endereco
		((ITERACAO+=1))
		declare -p RESULTADOS
	done
fi
declare -p RESULTADOS
