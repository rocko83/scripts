#!/bin/bash
function AJUDA() {
	echo Erro de argumentos
	echo Exemplo:
	echo $0 \<Arquivo\|Diretorio\> \<grupo\|usuario\> \<id atual\> \<id novo\>
	echo $0 \<Arquivo\|Diretorio\> \<listar\>
}
if [ $# -eq 4 ]
then
	export ANTES=$3
	export DEPOIS=$4
	find $1 | \
	while read objeto
	do
		export objeto_uid=$(stat $objeto | grep ^Access | grep Uid | awk '{print $5}' | sed -e "s/\///g")
		export objeto_gid=$(stat $objeto | grep ^Access | grep Uid | awk '{print $9}' | sed -e "s/\///g")
		case $2 in
			usuario)
				if [ $objeto_uid -eq $ANTES ]
				then
					chown $DEPOIS $objeto
				fi
				;;
			grupo)
				if [ $objeto_gid -eq $ANTES ]
				then
					chown :$DEPOIS $objeto
				fi
				;;
			*)
				AJUDA
				;;
		esac
	done
else
	if [ $# -eq 2 ]
	then
		if [ "$2" == "listar" ]
		then
			find $1 | \
			while read objeto
			do
				export objeto_uid=$(stat $objeto | grep ^Access | grep Uid | awk '{print $5}' | sed -e "s/\///g")
				export objeto_gid=$(stat $objeto | grep ^Access | grep Uid | awk '{print $9}' | sed -e "s/\///g")
				echo $objeto $objeto_uid $objeto_gid
			done
		fi
	else
		AJUDA
		exit 1
	fi
fi
