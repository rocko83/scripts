#!/bin/bash
export TEMPOFILE=/tmp/backup.sh.tmp
export TEMPOLISTA=/tmp/backup.sh.lista
export DESTINO=/media/damato/wd_crypt/netshoes
export DATA=$(date +"%y%m%d")
export DIRDESTINO=$DESTINO/$DATA
function ajuda() {
	echo falta de argumentos
	echo criar\/remover\/backup\/home\/gerahome\/tudo
}
function criar() {
	temporario=$(mktemp -d)
	echo $temporario > $TEMPOFILE
	lvcreate -s -L 20G -n snaph ubuntu-vg/damatoluks
	cryptsetup open --type luks /dev/ubuntu-vg/snaph  snaph
	mount -o ro /dev/mapper/snaph $temporario
}
function remover() {
	temporario=$(cat $TEMPOFILE)
	umount $temporario
	cryptsetup close /dev/mapper/snaph
	lvremove -f ubuntu-vg/snaph
}
function home() {
	mkdir -p $DIRDESTINO
	echo Efetuando backup do HOME
	temporario=$(cat $TEMPOFILE)
	cd $temporario
	tamanho=$(cat $TEMPOLISTA| xargs -i du -sk {} | awk '{s = s + $1} END {print s}')
	echo $tamanho | awk '{print $1 / 1024 ^2}'| xargs -i echo Comprimindo {} GB
	tar cf - $(cat $TEMPOLISTA) | pv -s "$tamanho"k | pigz -p 4 -9 > $DIRDESTINO/home.tgz
	cd -
}
function gera_lista_home() {
	echo Gerando lista do HOME
	temporario=$(cat $TEMPOFILE)
	ls -1a $temporario | egrep -wv "^programas|^Pictures|^projetos|^Downloads|^Downloads2|^Documents|^lost\+found|^tmp|^VBOX|^Videos|^.$|^..$" > $TEMPOLISTA
	echo Lista gerada em $TEMPOLISTA
}
function backup() {
	echo Efetuando backups
	temporario=$(cat $TEMPOFILE)
	comprimir $temporario/VBOX/Producao/wiki/ $DIRDESTINO/wiki.tgz
	#comprimir $temporario/VBOX/Producao/Win7-netshoes/ $DIRDESTINO/w7.tgz
	#comprimir $temporario/VBOX/Producao/NETSHOES-W10/ $DIRDESTINO/NETSHOES-W10.tgz
	comprimir $temporario/projetos/ $DIRDESTINO/projetos.tgz
	comprimir $temporario/programas/ $DIRDESTINO/programas.tgz
	comprimir $temporario/Pictures/ $DIRDESTINO/pic.tgz
	comprimir $temporario/Documents/ $DIRDESTINO/doc.tgz
}
if [ $# -ne 1 ]
then
	ajuda
	exit 1
fi
case $1 in
	criar)
		criar
		;;
	remover)
		remover
		;;
	backup)
		backup
		;;
	gerahome)
		gera_lista_home
		;;
	home)
		home
		;;
	tudo)
		gera_lista_home
		home
		backup
		;;
	*)
		ajuda
		exit 1
		;;
esac
