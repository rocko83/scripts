#!/bin/#!/usr/bin/env bash
function AJUDA() {
	echo ajuda
}
function PINGAR() {
	RETORNO=$(ping -c 1 $1)
	echo $RETORNO\;$1
}
if [ $# -eq 0 ]
then
	AJUDA
	exit 1
else
	ARRAY=()
	declare -a ARRAY
	ARRAY+=$(cat $1)
fi
