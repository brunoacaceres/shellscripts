#!/bin/bash

#
# chkconfig: 35 80 05
# description: Deploy script for GLASSFISH Tendencia
# Autor: Bruno de Abreu Caceres
# Data: Jan/2014

#Variaveis Glassfish e Oracle

JAVA_HOME=/opt/jdk1.6.0_45
JDK_HOME=$JAVA_HOME
CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar:
export ORACLE_HOME=/opt/oracle/product/11.2/client
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
PATH=$ORACLE_HOME/bin:$JAVA_HOME/bin:$PATH
export JDK_HOME JAVA_HOME CLASSPATH

#Variaveis Glassfish
GFHOME=/opt/glassfish3/glassfish
#DOMAINS="domain1 domain2"

#Usuario Shell para conexao remota
USERSO=oracle
CMDUSER="su --login  $USERSO --command "
#SISTEMA="SGV"

ENVIAEMAIL="infra.java@redetendencia.com.br"

#-----------------------------WEB------------------------------------------------------------

PUBLICAHOME=/opt/publica
TODAY="`date +%Y%m%d`"

#Busca de Ambiente que existem aplicacoes a serem publicadas
PUBLICAWEB="`/bin/find "$PUBLICAHOME" -name "*.ear" |  /bin/awk -F "/" '{print $4}' | /bin/egrep -o ^[A-Z]*| /usr/bin/uniq | /usr/bin/tail -n1 `"

PIDPUB=`ps ax | grep "/opt/publica/deploywebsgv.sh" | grep -v grep | awk -F " " '{print $1}'`	

PIDSGV="`cat $PUBLICAHOME/PIDSGV.pid`"

echo "o PID DO PUBLICADOR" $PIDPUB
echo "o PID SGV EH " $PIDSGV

if [ "$PUBLICAWEB" != ""  ]
then
        for i in $PUBLICAWEB
        do
                AMBIENTE=${i}

               if [ "$AMBIENTE" = "SIT" ] || [ "$AMBIENTE" = "UAT" ] && [ "$PIDSGV" = "" ] 
                then
			LOGS=/opt/publica/log/RelatorioPublicaGF3.log
                        EXPURGO_LOGS=/opt/publica/log/"Publicacao-GF3-`date +%Y%m%d`.log"
#                        #Armazenando logs
                        exec > $LOGS 2>&1
                        echo $PIDPUB > $PUBLICAHOME/PIDSGV.pid
                        PIDSGV="`cat $PUBLICAHOME/PIDSGV.pid`"
                        echo "o PID EH " $PIDSGV
                        INSTHOME="/opt/glassfish3/glassfish/nodes/localhost-domain1"
                        GFCONF="/opt/glassfish3/glassfish/config"
                        PORT="--port 4848"
                        #PORT="--port 9148"
                        DOMAIN="domain1"

                        #IPS DOS SERVIDOR DOS AMBIENTES SIT
                        if [ "$AMBIENTE" = "SIT"  ]
                        then
                                IP1="172.17.57.2"

			elif [ "$AMBIENTE" = "UAT"  ]
			then
			 	IP1="172.17.57.4"
                        fi

                       #Iniciando Dominio DAS

                        pid=`$CMDUSER "/usr/bin/ssh $IP1 -C ps ax | grep "$DOMAIN" | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                        if [ "$pid" != "" ]; then
                                echo
                                echo "`date +%c` - O Dominio $DOMAIN ESTA RODANDO NO PID $pid."
                                echo

                        else
                                echo
                                echo -n "`date +%c` - Iniciando Instancia $DOMAIN SGV - $IP1 : "
                                echo
                                 `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-domain $DOMAIN -W $GFCONF/pwd.conf"`
                                echo
                        fi

                        SGVWEBNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgv/web/" | grep ear | /bin/awk -F "-" '{print $0}'| /bin/sort | /usr/bin/tail -n1`"
                        VERSAONOVA=`echo "$SGVWEBNOVO" |  /bin/awk -F "-" '{print $3}' | sed -e s'|.ear||'`

                        echo "SGVWEBNOVO = $SGVWEBNOVO"

                        if [ "$SGVWEBNOVO" != "" ] 
                        then

                                APPWEBNOVA=$SGVWEBNOVO
                                APPSWEB=`echo $SGVWEBNOVO |  /bin/awk -F "-" '{print $1"-"$2}'`
				APP=`echo "$APPSWEB" | tr "a-z" "A-Z"`

                                SISTEMA=`echo $APP |  /bin/awk -F "-" '{print $1}'`
        #                        TIPO=`echo $APP |  /bin/awk -F "-" '{print $2}'`


	                        if [ "$APPSWEB" = "sgv-ear"  ]
	                        then
        	                        INSTANCIA="SGV-WEB"
					TIPO="WEB"
				else 
	                                INSTANCIA="$APP"
		                        TIPO=`echo $APP |  /bin/awk -F "-" '{print $2}'`
	                        fi

                                echo "var APPSWEB= "$APPSWEB
                                echo
                                DEPLOYWEBATUAL=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/ls $INSTHOME/$INSTANCIA/applications |grep "$INSTANCIA""` #"$APPSWEB""`
                                echo "WEB ATUAL $DEPLOYWEBATUAL"
                                echo "WEB NOVA $APPWEBNOVA"
                                echo
                                #Copiando Arquivos para deploy
                                echo "Copiando arquivos do ambiente $AMBIENTE para a pasta de publicacao - $IP1"
                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgv/web/$APPSWEB*" $IP1:$PUBLICAHOME/$AMBIENTE/sgv/web/"`
                                echo

                                #VERIFICANDO STATUS DA INSTANCIA

          INSTATIVA=`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin  --passwordfile $GFCONF/pwd.conf $PORT list-instances | grep $INSTANCIA" | awk -F " " '{print $2}' | grep -c running`
                                echo $INSTATIVA
                                #echo
                                if [ "$INSTATIVA" = "1"  ]
                                then
                                        echo
                                        echo "`date +%c` - Parando instancia $INSTANCIA"
					"`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin --passwordfile $GFCONF/pwd.conf $PORT stop-local-instance $INSTANCIA"`"
                                fi

                                if [ "$DEPLOYWEBATUAL" != "" ]
                                then
					echo
                                        echo "`date +%c` -  Executando Undeploy $DEPLOYWEBATUAL na instancia $INSTANCIA"
					 "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin  --passwordfile $GFCONF/pwd.conf $PORT undeploy  --target $INSTANCIA  $DEPLOYWEBATUAL"`"
                                 fi
                                 
				 echo
                                 echo "`date +%c` - Executando Deploy $APPWEBNOVA na instancia $INSTANCIA"
				
#                                if [ $APPSWEB = "frontend-conciliador" ]
#                                then
#					NAMECONTEXT="--name  $APPSWEB-$VERSAONOVA-$AMBIENTE --contextroot frontend-conciliador"
#                               else
					NAMECONTEXT="--name $INSTANCIA-$VERSAONOVA-$AMBIENTE"
#                               fi

  				"`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin  --passwordfile $GFCONF/pwd.conf $PORT deploy $NAMECONTEXT  --target $INSTANCIA  $PUBLICAHOME/$AMBIENTE/sgv/web/$APPWEBNOVA   "`"

                                 DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/find $GFHOME/domains/$DOMAIN/applications/__internal/$INSTANCIA-$VERSAONOVA-$AMBIENTE/ -name '$APPSWEB*.ear'"`
                                 
				 if [ "$DPLPUB" != "" ]
                                 then
                                        echo
                                        echo $DPLPUB
                                        echo
                                        echo "`date +%c` - Iniciando instancia $INSTANCIA"
					`$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin --passwordfile $GFCONF/pwd.conf $PORT start-local-instance --sync full $INSTANCIA "`

                                        #Checagem MD5 entre a publicacao a ser realizada e a publicada
                                        MD5DPLNOV=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $PUBLICAHOME/$AMBIENTE/sgv/web/$APPSWEB*" | /bin/awk -F " " '{print $1}'`
                                        echo "MD5 Deploy novo $MD5DPLNOV"
                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $DPLPUB" | /bin/awk -F "/" '{print $1}'`
                                        echo "MD5 Deploy Publicado $MD5DPLPUB"

                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                        then
						echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
                                                exit 1;

                                        else
						echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
                                                echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
                                               `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                        fi

#                                        echo
                                        echo "`date +%c` - Removendo  deploy $APPWEBNOVA remoto"
                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/web/$APPSWEB*"`"
#                                        echo
                                        echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                        "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/web/$APPSWEB*`"
#                                        echo
                                        echo "-----------------------------FIM--------------------------"

                                        else
						echo "Deploy nao realizado"
                                                `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA ERROR"`
                                                echo "`date +%c` - Removendo  deploy $SGVWEBNOVO remoto"
                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/web/$APPSWEB*"`"
                                                echo
                                                echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/web/$APPSWEB*`"
                                                `echo "" ` > "$PUBLICAHOME/PIDSGV.pid"
                                                echo
                                                echo "-----------------------------FIM--------------------------"
                                                exit 1;
                                        fi

                                         echo "Expurgando LOGS"
                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                        echo "Enviando Email de Publicacao"
                                        echo "-----------------------------FIM--------------------------"
                                        echo

                                       `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA" -r "infra.java@redetendencia.com.br" -q $LOGS $ENVIAEMAIL`
 
                                        `echo "" ` > "$PUBLICAHOME/PIDSGV.pid"
                                        PIDSGV=""
                                        exit 1;
				fi

                else
  	              echo "Publicacao em Andamento"
               	fi
        done

else

	echo "`date +%c` - Nao existem deploys de WEB para atualizar"
fi

