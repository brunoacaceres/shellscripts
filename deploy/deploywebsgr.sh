#!/bin/bash

#
# chkconfig: 35 80 05
# description: Deploy script for GLASSFISH Tendencia
# Autor: Bruno de Abreu Caceres
# Data: Jan/2014

#Variaveis Jetty e Oracle

JAVA_HOME=/opt/jdk1.8.0_20
JDK_HOME=$JAVA_HOME
CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar:
export ORACLE_HOME=/opt/oracle/product/11.2/client
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export JETTYHOME=/opt/jetty8
PATH=$ORACLE_HOME/bin:$JAVA_HOME/bin:$JETTYHOME/bin:$PATH
export JDK_HOME JAVA_HOME CLASSPATH

#Usuario Shell para conexao remota
USERSO=oracle8
CMDUSER="su --login  $USERSO --command "
SISTEMA="SGR"

#-----------------------------WEB------------------------------------------------------------

PUBLICAHOME=/opt/publica
TODAY="`date +%Y%m%d`"
INST=01
HOMEPUBLICA=/opt/$APPAMBIENTE
ENVIAEMAIL="infra.java@redetendencia.com.br"
#Busca de Ambiente que existem aplicacoes a serem publicadas
PUBLICAWEB="`/bin/find "$PUBLICAHOME" -name "sgr*" |  /bin/awk -F "/" '{print $4}' | /bin/egrep -o ^[A-Z]*| /usr/bin/uniq`"

PIDPUB=`ps ax | grep "/opt/publica/deploywebsgr.sh" | grep -v grep | awk -F " " '{print $1}'`	

PIDSGR="`cat $PUBLICAHOME/PIDSGR.pid`"

echo "o PID DO PUBLICADOR" $PIDPUB
echo "o PID SGR EH " $PIDSGR

echo "PUBLICA WEB...: " $PUBLICAWEB


if [ "$PUBLICAWEB" != ""  ]
then
        for i in $PUBLICAWEB
        do
                AMBIENTE=${i}

                if  [ "$AMBIENTE" = "SIT" ] || [ "$AMBIENTE" = "UAT" ] && [ "$PIDSGR" = "" ]
       	        then
                        echo $PIDPUB > $PUBLICAHOME/PIDSGR.pid
 		        PIDSGR="`cat $PUBLICAHOME/PIDSGR.pid`"
                        #Verificando novos deploys
        	        SGRWEBNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgr/web/" | grep "sgr*" | /bin/awk -F "-" '{print $0}'| /bin/sort | /usr/bin/tail -n1`"

	                #IPS DOS SERVIDOR DOS AMBIENTES SIT
	                if [ "$AMBIENTE" = "SIT"  ]
        	        then
                                IP1="172.17.57.2"
	
	                elif [ "$AMBIENTE" = "UAT"  ]
	                then
	         	       IP1="172.17.57.4"
	                fi

			#Verificando qual SGR (web ou ws)
                        APPWEBNOVA=$SGRWEBNOVO
                        APPSWEB=`echo $SGRWEBNOVO |  /bin/awk -F "-" '{print $1"-"$2}'`
				
                        if [ "$APPSWEB" = "sgr-ws.war"  ]
	                then
       		                APP="sgr-ws.war"
				TIPO="WS"
	       	        else
                                APP="sgr.war"
				TIPO="WEB"
                        fi

                       	if [  "$SGRWEBNOVO" != "" ]
	                then
                                echo
               	                echo "`date +%c` ----INICIANDO COPIA EM HOMOLOGACAO $AMBIENTE SGR WEB - $IP1 ------"

                       	        #Removendo arquivos anteriores do servidor remoto
                              	echo "`date +%c` - Removendo arquivos do ambiente $AMBIENTE-WEB para a pasta de publicacao"
                                `$CMDUSER "/usr/bin/ssh $IP1 -C /bin/rm -f $PUBLICAHOME/$AMBIENTE/sgr/web/$APP"`
                                #Copiando arquivos para o servidor remoto
                                echo "`date +%c` - Copiando arquivos do ambiente $AMBIENTE-WEB para a pasta de publicacao"
                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgr/web/$APP" $IP1:$PUBLICAHOME/$AMBIENTE/sgr/web/"`
	
       	                        #Parando Jetty
               	                echo "`date +%c` - Parando Jetty"
                       	        "`$CMDUSER "/usr/bin/ssh $IP1 -C  /opt/publica/sgr stop"`"

                               	#Removendo Deploy anterior
                                echo "`date +%c` - Removendo Deploy anterior"
                                `$CMDUSER "/usr/bin/ssh $IP1 -C /bin/rm -f $JETTYHOME/webapps/$APP"`

                                #Publicando Sistema
                                echo "`date +%c` - Copiando artefato para pasta webapps do jetty"
                                `$CMDUSER "/usr/bin/ssh $IP1 -C /bin/cp $PUBLICAHOME/$AMBIENTE/sgr/web/$APP $JETTYHOME/webapps/"`
	
                                #Iniciando Jetty
                                echo "`date +%c` - Iniciando Jetty"
                                "`$CMDUSER "/usr/bin/ssh $IP1 -C /opt/publica/sgr start"`"
	
                                #Checagem MD5 entre a publicacao a ser realizada e a publicada
                                MD5DPLNOV=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $PUBLICAHOME/$AMBIENTE/sgr/web/$APP*" | /bin/awk -F " " '{print $1}'`
                                echo "MD5 Deploy novo $MD5DPLNOV"
                                MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum  $JETTYHOME/webapps/$APP*" | /bin/awk -F "/" '{print $1}'`
                                echo "MD5 Deploy Publicado $MD5DPLPUB"

                                if [ $MD5DPLNOV != $MD5DPLPUB ]
                                then
	                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
                                        exit 1;

                                else
                                        echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
                                        echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-WEB $APPWEBNOVA"
                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                fi

                                #Removendo Deploy apos copia
                                echo "`date +%c` - Removendo deploy $SGRWEBNOVO local"
                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgr/web/$APP`"

                                echo
                                echo "`date +%c` -----------------------------FIM--------------------------"
                                `/bin/echo | /bin/mail -s "Publicacao $SGRWEBNOVO-$AMBIENTE $j" -r "infra.java@redetendencia.com.br" -q "/opt/publica/log/RelatorioPublicaSGR.log" $ENVIAEMAIL`
			fi

               		else
	        		echo "Publicacao em Andamento"
               		fi
	
       	        	`echo "" ` > "$PUBLICAHOME/PIDSGR.pid"
                	 PIDSGR=""
       	done

else
	echo "`date +%c` - Nao existem deploys de WEB para atualizar"
fi

