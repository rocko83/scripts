#!/bin/bash
TEMPLATE=template.rocko83.com.br
USUARIO=operador
NOME=$1
ENDERECO=$(echo $NOME | awk -F - '{print $2}')
if [ $# -ne 1 ]
then
	echo falta de argumentos
	exit 1
fi
echo Ligando guest $NOME
vboxmanage startvm $NOME --type headless
while true
do
        ping -c 1 template.rocko83.com.br 2> /dev/null
        retorno=$?
        if [ $retorno -eq 0 ]
        then
                sleep 10
		echo $NOME on-line
		break
        fi
	echo $NOME ainda offline
        sleep 1
done
echo Configurando hostname
ssh $USUARIO@$TEMPLATE sudo hostnamectl set-hostname $NOME.rocko83.com.br 2> /dev/null
ssh $USUARIO@$TEMPLATE sudo sed -i "s/ubuntu/$NOME/g" 2> /dev/null
echo Configurando rede
ssh $USUARIO@$TEMPLATE sudo sed -i "s/192.168.56.150/192.168.56.$ENDERECO/g" /etc/network/interfaces 2> /dev/null
echo Reiniciando
ssh $USUARIO@$TEMPLATE sudo reboot 2> /dev/null
while true
do
	ping -c 1 $NOME.rocko83.com.br 2> /dev/null
	retorno=$?
	if [ $retorno -eq 0 ]
	then
		sleep 10
		echo  $USUARIO@$NOME.rocko83.com.br on-line
		ssh $USUARIO@$NOME.rocko83.com.br
		exit
	fi
	echo  $USUARIO@$NOME.rocko83.com.br ainda off-line
	sleep 1
done
