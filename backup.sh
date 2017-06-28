#!/bin/bash -x
function ajuda() {
	echo falta de argumentos
	echo criar\/remover\/backup\/home\/gerahome\/tudo\/config \| \[\Diretprio de destino\]
}
function criar() {
	temporario=$(mktemp -d)
	echo $temporario > $TEMPOFILE
	lvcreate -s -L 10G -n snaph ubuntu-vg/damatoluks
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
	ls -1a $temporario | egrep -wv "^Android|^programas|^Pictures|^projetos|^Downloads|^Downloads2|^Documents|^lost\+found|^tmp|^VBOX|^Videos|^.$|^..$|^ownCloud" > $TEMPOLISTA
	echo Lista gerada em $TEMPOLISTA
}
function backup() {
	echo Efetuando backups
	temporario=$(cat $TEMPOFILE)
	comprimir $temporario/VBOX/Producao/wiki/ $DIRDESTINO/wiki.tgz
	comprimir $temporario/VBOX/Producao/NETSHOES-W10/ $DIRDESTINO/NETSHOES-W10.tgz
	comprimir $temporario/projetos/ $DIRDESTINO/projetos.tgz
	#comprimir $temporario/programas/ $DIRDESTINO/programas.tgz
	comprimir $temporario/Pictures/ $DIRDESTINO/pic.tgz
	comprimir $temporario/Documents/ $DIRDESTINO/doc.tgz
}
function config() {
	apt list --installed > $DIRDESTINO/apt-list-installed
	sudo $(which comprimir) /etc $DIRDESTINO/etc.tgz
	sudo chown $(grep $(id -u) /etc/passwd | awk -F : '{print $1}'):$(grep $(id -u) /etc/passwd | awk -F : '{print $1}') $DIRDESTINO/etc.tgz
}
DESTINOPADRAO=/media/damato/wd_crypt/netshoes
if [ $# -eq 0 ]
then
	ajuda
	exit 1
fi
if [ $# -eq 2 ]
then
	if [ -a $2 ]
	then
		export DESTINO=$(echo $2 | sed -e "s/\/$//g")
	else
		echo erro caminho de destino, verifique se $2 existe
		exit 1
	fi
else
	if [ -a $DESTINOPADRAO ]
	then
		export DESTINO=$DESTINOPADRAO
	else
		echo Erro no caminho de destino, verifique se $DESTINO existe
		exit 1
	fi
fi
export TEMPOFILE=/tmp/backup.sh.tmp
export TEMPOLISTA=/tmp/backup.sh.lista
export DATA=$(date +"%y%m%d")
export DIRDESTINO=$DESTINO/$DATA
case $1 in
	criar)
		criar
		;;
	remover)
		remover
		;;
	apagar)
		remover
		;;
	backup)
		mkdir -p $DIRDESTINO
		backup
		;;
	gerahome)
		gera_lista_home
		;;
	home)
		mkdir -p $DIRDESTINO
		home
		;;
	tudo)
		mkdir -p $DIRDESTINO
		config
		gera_lista_home
		home
		backup
		;;
	config)
		config
		;;
	*)
		ajuda
		exit 1
		;;
esac
