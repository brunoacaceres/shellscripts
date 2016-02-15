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
PUBLICAWEB="`/bin/find "$PUBLICAHOME" -name "sgr*.war" |  /bin/awk -F "/" '{print $4}' | /bin/egrep -o ^[A-Z]*| /usr/bin/uniq`"

PIDPUB=`ps ax | grep "/opt/publica/deploywebprdsgr.sh" | grep -v grep | awk -F " " '{print $1}'`	

PIDSGRPRD="`cat $PUBLICAHOME/PIDSGRPRD.pid`"

echo "o PID DO PUBLICADOR" $PIDPUB
echo "o PID SGR EH " $PIDSGRPRD

echo "PUBLICA WEB...: " $PUBLICAWEB


if [ "$PUBLICAWEB" != ""  ]
then
        for i in $PUBLICAWEB
        do
                AMBIENTE=${i}

                if  [ "$AMBIENTE" = "PRD" ] && [ "$PIDSGRPRD" = "" ]
       	        then
                        echo $PIDPUB > $PUBLICAHOME/PIDSGRPRD.pid
 		        PIDSGRPRD="`cat $PUBLICAHOME/PIDSGRPRD.pid`"
                        #Verificando novos deploys
        	        SGRWEBNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgr/web/" | grep sgr | /bin/awk -F "-" '{print $0}'| /bin/sort | /usr/bin/tail -n1`"

	                #IPS DOS SERVIDOR DOS AMBIENTES PRD 
	                if [ "$AMBIENTE" = "PRD"  ]
        	        then
                                IP1="172.16.57.5"
	                fi

			#Verificando qual SGR (web ou ws)
                        APPWEBNOVA=$SGRWEBNOVO
                        APPSWEB=`echo $SGRWEBNOVO |  /bin/awk -F "-" '{print $1"-"$2}'`
				
                        if [ "$APPSWEB" = "sgr-ws.war"  ]
	                then
       		                APP="sgr-ws.war"
	       	        else
                                APP="sgr.war"
                        fi

                       	if [  "$SGRWEBNOVO" != "" ]
	                then
                                echo
               	                echo "`date +%c` ----INICIANDO COPIA EM $AMBIENTE SGR WEB - $IP1 ------"


                               #Criando pasta remota
                                echo "`date +%c` - Criando pasta Remota"
                                 "`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/mkdir -p  $PUBLICAHOME/$AMBIENTE/sgv/web/$TODAY"`"


                       	        #Removendo arquivos anteriores do servidor remoto
#                             	echo "`date +%c` - Removendo arquivos do ambiente $AMBIENTE-WEB para a pasta de publicacao"
#                               `$CMDUSER "/usr/bin/ssh $IP1 -C /bin/rm -f $PUBLICAHOME/$AMBIENTE/sgr/web/$TODAY/$APP"`
                                #Copiando arquivos para o servidor remoto
                                echo "`date +%c` - Copiando arquivos do ambiente $AMBIENTE-WEB para a pasta de publicacao"
                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgr/web/$APP" $IP1:$PUBLICAHOME/$AMBIENTE/sgr/web/$TODAY/"`
	
                                #Checagem MD5 entre a publicacao a ser realizada e a publicada
                                MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $PUBLICAHOME/$AMBIENTE/sgr/web/$APP" | /bin/awk -F " " '{print $1}'`
                                echo "MD5 Deploy novo $MD5DPLNOV"
                                MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum  $PUBLICAHOME/$AMBIENTE/sgr/web/$TODAY/$APP" | /bin/awk -F "/" '{print $1}'`
                                echo "MD5 Deploy Publicado $MD5DPLPUB"

                                if [ $MD5DPLNOV != $MD5DPLPUB ]
                                then
	                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
                                        exit 1;

                                else
                                        echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
                                        echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-WEB $APPWEBNOVA"
                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-WEB $APPWEBNOVA"`
                                fi

                                #Removendo Deploy apos copia
                                echo "`date +%c` - Removendo deploy $SGRWEBNOVO local"
#                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgr/web/$APP`"

                                echo
                                echo "`date +%c` -----------------------------FIM--------------------------"
#                                `/bin/echo | /bin/mail -s "Publicacao $SGRWEBNOVO-$AMBIENTE $j" -r "infra.java@redetendencia.com.br" -q "/opt/publica/log/RelatorioPublicaSGR.log" $ENVIAEMAIL`
			fi

               		else
	        		echo "Publicacao em Andamento"
               		fi
	
       	        	`echo "" ` > "$PUBLICAHOME/PIDSGRPRD.pid"
                	 PIDSGRPRD=""
       	done

else
	echo "`date +%c` - Nao existem deploys de WEB para atualizar"
fi

