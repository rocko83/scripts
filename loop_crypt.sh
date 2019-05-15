#!/bin/bash -x
function HIGH() {
	tr -dc A-Za-z0-9!?@#_ < /dev/urandom | head -c ${tamanho} | xargs
}
function MEDIUM() {
	tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${tamanho} | xargs
}
function LOW() {
	tr -dc A-Za-z0-9 < /dev/urandom | head -c ${tamanho} | xargs
}
function NUMBER() {
	tr -dc 0-9 < /dev/urandom | head -c ${tamanho} | xargs
}
function HEXA() {
	tr -dc A-F0-9 < /dev/urandom | head -c ${tamanho} | xargs
}
function FAKEWWN() {
	tr -dc A-F0-9 < /dev/urandom | head -c 16 | xargs  | sed -e "s/^0x//g" | sed -r "s/../&:/g" | sed -e "s/$://g" | tr "a-z" "A-Z" | sed -e "s/:$//g"
}
function BANNER() {
  case $1 in
    titulo)
        echo -e "\e[45m"
        echo $(date +"%Y-%m-%d_%H-%M_%S")\;$2
        echo -en "\e[0m"
        ;;
    conteudo)
        echo -e "\e[44m"
        echo $(date +"%Y-%m-%d_%H-%M_%S")\;$2
        echo -en "\e[0m"
        ;;
    sucesso)
        echo -e "\e[42m"
        echo $(date +"%Y-%m-%d_%H-%M_%S")\;$2
      	echo -en "\e[0m"
        ;;
    erro)
        echo -e "\e[41m"
        echo $(date +"%Y-%m-%d_%H-%M_%S")\;$2
        echo -en "\e[0m"
				exit 1
        ;;
    *)
        EXITNOW
        ;;
  esac

}
function Tempfunc() {
	case $1 in
	criar)
		$CMD_MKTEMP -p /tmp --suffix ssh-netshoe
		;;
	apagar)
		$CMD_RM -f $2
		;;
	*)
		echo erro
		exit 1
		;;
	esac
}
function looplivre() {
		export primeiro=$1
    seq $primeiro 1000 | \
    while read valor
    do
        retorno=$(losetup -a | grep -w /dev/loop$valor| wc -l)
        if [ $retorno -eq 0 ]
            then echo $valor /dev/loop$valor
            break
        fi
    done
}
function abrirloops() {
		export seqcontroller=$(Tempfunc criar)
		echo 1 > $seqcontroller
    ls -1 $1/data.* | while read datafile
    do
			#echo Montando loop para $datafile
			looplivre $(cat $seqcontroller)| while read sequencia looplivre
			do
				losetup $looplivre $datafile
				echo $sequencia > $seqcontroller
      done
    done
}
function listar() {
  ls -1 $1    |\
  while read valor
  do
   losetup -a | \
   grep -w $1/$valor| \
   awk -F : '{print $1}'
  done
}
function format() {
  # cryptsetup luksFormat --type luks2  $1 code.1
  listar $1 | while read loopdevice
  do
    losetup $loopdevice | \
    awk '{print $3}' | \
    sed -e "s/(//g" -e "s/)//g" | \
    awk -F . '{print $2}' | \
    while read indice
    do
      # echo Formatando $loopdevice $indice
      #echo $loopdevice $indice
      cryptsetup luksFormat --type luks2  $loopdevice code.$indice
    done
  done
}
function gencode() {
  export tamanho=200
	listar $1 | while read loopdevice
  do
    losetup $loopdevice | \
    awk '{print $3}' | \
    sed -e "s/(//g" -e "s/)//g" | \
    awk -F . '{print $2}' | \
    while read indice
    do
      # echo Criando chave para  $loopdevice $indice
      HIGH > code.$indice
    done
  done
  # seq 1 $(listar $1 | wc -l ) | \
  # while read indice
  # do
  #   HIGH > code.$indice
  # done
}
function abrir_crypt() {
  listar $1 | while read loopdevice
  do
    losetup $loopdevice | \
    awk '{print $3}' | \
    sed -e "s/(//g" -e "s/)//g" | \
    awk -F . '{print $2}' | \
    while read indice
    do
      # echo $loopdevice $indice
      # cryptsetup luksFormat --type luks2  $loopdevice code.$indice
      cryptsetup open --type luks2 --key-file code.$indice $loopdevice data.$indice
    done
  done
}
function criar_vg() {
  vgcreate datacrypt $(find /dev/mapper/ -type l -name data.\* )
}
function exportarvg() {
	vgchange -an datacrypt
	vgexport datacrypt
}
function importarvg() {
	vgimport datacrypt
	vgchange -ay datacrypt

}
function fechar_crypt() {

	find /dev/mapper/ -type l -name data.[0-9]\* -exec cryptsetup close {} \;

}
function fecharloop(){
	losetup -a  |grep data.[0-9] | awk -F : '{print $1}' | xargs -i losetup -d {}
}

# export CAMINHO=$(echo $1 | sed -e "s/\/$//g")
# abrirloops $CAMINHO
# listar $CAMINHO
# # gencode $CAMINHO
# # format $CAMINHO
# abrir_crypt $CAMINHO
# # criar_vg
# exportarvg
# # fechar_crypt
# # fecharloop
if [ $# -eq 0 ]
then
	exit 1
else
	if [ $# -eq 2 ]
	export CAMINHO=$(echo $2 | sed -e "s/\/$//g")
	then
		case $1 in
			criar)
			  abrirloops $CAMINHO
				gencode $CAMINHO
				format $CAMINHO
				abrir_crypt $CAMINHO
				criar_vg
				importarvg
				;;
			abrir)
				abrirloops $CAMINHO
				#listar $CAMINHO
				abrir_crypt $CAMINHO
				importarvg
				;;
		esac
	fi
	if [ $# -eq 1 ]
	then
		case $1 in
			fechar)
				exportarvg
				fechar_crypt
				fecharloop
				;;
		esac
	fi
fi
