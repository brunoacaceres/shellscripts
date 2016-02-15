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
GFHOME=/opt/glassfish4/glassfish
#DOMAINS="domain1 domain2"

#Usuario Shell para conexao remota
USERSO=oracle7
CMDUSER="su --login  $USERSO --command "
#SISTEMA="SGV"

ENVIAEMAIL="infra.java@redetendencia.com.br"

#-----------------------------WEB------------------------------------------------------------

PUBLICAHOME=/opt/publica
TODAY="`date +%Y%m%d`"
INST=01
HOMEPUBLICA=/opt/$APPAMBIENTE

#Busca de Ambiente que existem aplicacoes a serem publicadas
PUBLICAWEB="`/bin/find "$PUBLICAHOME" -name  "*\.[ew]ar" |  /bin/awk -F "/" '{print $4}' | /bin/egrep -o ^[A-Z]*| /usr/bin/uniq`"

PIDPUB=`ps ax | grep "/opt/publica/deployconchml.sh" | grep -v grep | awk -F " " '{print $1}'`	

#PIDHML="`cat $PUBLICAHOME/PIDHML.pid`"
PIDCONCHML="`cat $PUBLICAHOME/PIDCONCHML.pid`"

echo "PUBLICA WEB" $PUBLICAWEB
echo "o PID DO PUBLICADOR" $PIDPUB
echo "o PID CONC HML EH " $PIDCONCHML

if [ "$PUBLICAWEB" != ""  ]
then
        for i in $PUBLICAWEB
        do
              AMBIENTE=${i}

              SGVWEBNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgv/host/" | egrep "*\.[ew]ar" | /bin/awk -F "-" '{print $0}'| /bin/sort | /usr/bin/tail -n1`"
              VERSAONOVA=`echo "$SGVWEBNOVO" |  /bin/awk -F "-" '{if($1 == "frontend" ){print$3;}else{print$4};}' | sed 's/.[we]ar//g'`

               if [ "$AMBIENTE" = "SIT" ] || [ "$AMBIENTE" = "UAT" ] || [ "$AMBIENTE" = "INT" ] && [ "$PIDCONCHML" = "" ] && [ "$SGVWEBNOVO" != "" ] 
                then
                        EXPURGO_LOGS=/opt/publica/log/"Publicacao-CONC-HML-`date +%Y%m%d`.log"
                        LOGS=/opt/publica/log/RelatorioPublicaConciliadores.log
#                        #Armazenando logs
                        exec > $LOGS 2>&1
                        echo "----------------------INICIO------------------------"
			
                        echo $PIDPUB > $PUBLICAHOME/PIDCONCHML.pid
                        PIDCONCHML="`cat $PUBLICAHOME/PIDCONCHML.pid`"
                        echo "o PID EH " $PIDCONCHML
                        INSTHOME="/opt/glassfish4/glassfish/nodes/localhost-domain2"
                        GFCONF="/opt/glassfish4/glassfish/config"
                        #PORT="-p 4848"
                        PORT="--port 9148"
                        DOMAIN="domain2"

                        #IPS DOS SERVIDOR DOS AMBIENTES SIT
                        if [ "$AMBIENTE" = "SIT"  ]
                        then
                                IP1="172.17.57.2"

                        elif [ "$AMBIENTE" = "UAT"  ]
                        then
                                IP1="172.17.57.4"

                        elif [ "$AMBIENTE" = "INT"  ]
                        then
                                IP1="172.17.57.3"
                        fi


                       #Iniciando Dominio DAS

                        pid=`$CMDUSER "/usr/bin/ssh $IP1 -C ps ax | grep "DAS" | grep "$DOMAIN" | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

			LIB=`$CMDUSER "/usr/bin/ssh $IP1 -C  /bin/ls -l $GFHOME/domains/domain2/lib | awk -F "/" '{print$'13'}'"`
			
			echo "Pid Domain" $pid
			echo "Listando pasta lib corrente=" $LIB

                        if [ "$LIB" != "lib-conciliador"  ] || [ "$pid" = "" ]
                        then
				#Alterando Link das Libs
				echo "`date +%c` - UNLINK Libs de $LIB "
				`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/unlink $GFHOME/domains/domain2/lib"`

	                        echo "`date +%c` - LINK Libs de lib-conciliador "
        	                `$CMDUSER "/usr/bin/ssh $IP1 -C /bin/ln -s $GFHOME/domains/domain2/lib-conciliador $GFHOME/domains/domain2/lib"`


                	        if [ "$pid" != "" ]; then
	                                echo
	                                echo -n "`date +%c` - Parando $DOMAIN SGV: "
					`$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin stop-domain $DOMAIN -W $GFCONF/pwd.conf"`
	                                echo
                                        echo -n "`date +%c` - Iniciando $DOMAIN SGV: "
                                        echo
                                         `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-domain $DOMAIN -W $GFCONF/pwd.conf"`
                                        echo
        	                else
                	                echo
                        	        echo -n "`date +%c` - Iniciando $DOMAIN SGV: "
                                	echo
	                                 `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-domain $DOMAIN -W $GFCONF/pwd.conf"`
        	                        echo
                	        fi
			else
				echo
				echo "Restart nao necessario pois as libs estao corretas"
			fi

                        #SGVWEBNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgv/host/" | grep "*\.[ew]ar" | /bin/awk -F "-" '{print $0}'| /bin/sort | /usr/bin/tail -n1`"
			#VERSAONOVA=`echo "$SGVWEBNOVO" |  /bin/awk -F "-" '{if($1=="tnd"){print$4;}else{print$3};}' | sed 's/.[we]ar//g'`

                        echo "SGVWEBNOVO = $SGVWEBNOVO"

                        if [ "$SGVWEBNOVO" != "" ] 
                        then

                                APPWEBNOVA=$SGVWEBNOVO
				#APPWEBNOVA=`echo $SGVWEBNOVO | sed 's/.[we]ar//g'`
                                #APPSWEB=`echo $SGVWEBNOVO |  /bin/awk -F "-" '{print $1"-"$2}'`
				APPSWEB=`echo $SGVWEBNOVO |  sed 's/\.[we]ar//g'`
				APPATUAL=`echo $APPSWEB |  /bin/awk -F "-" '{print $1"-"$2}'`
				APP=`echo "$APPSWEB" | tr "a-z" "A-Z"`
                                INSTANCIA="CONCILIADOR"
                                SISTEMA=`echo $APP |  /bin/awk -F "-" '{print $1}'`
                                TIPO=`echo $APP | /bin/awk -F "-" '{if($1=="FRONTEND"){print$2;}else{print$2};}'`

                                echo "var APPSWEB= "$APPSWEB
                                echo
                                DEPLOYWEBATUAL=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/ls $INSTHOME/$INSTANCIA/applications |grep "$APPATUAL""`
                                echo "WEB ATUAL $DEPLOYWEBATUAL"
                                echo "WEB NOVA $APPWEBNOVA"
                                echo
                                #Copiando Arquivos para deploy
                                echo "Copiando arquivos do ambiente $AMBIENTE para a pasta de publicacao"
                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgv/host/$APPSWEB*" $IP1:$PUBLICAHOME/$AMBIENTE/sgv/host/"`
                                echo

                                #VERIFICANDO STATUS DA INSTANCIA

          INSTATIVA=`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin  --passwordfile $GFCONF/pwd.conf $PORT list-instances | grep $INSTANCIA" | awk -F " " '{print $2}' | grep -c running`
                                echo $INSTATIVA
                                #echo

                                if [ "$DEPLOYWEBATUAL" != "" ]
                                then
                                        echo
                                        echo "`date +%c` -  Executando Undeploy $DEPLOYWEBATUAL na instancia $INSTANCIA"
                                         "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin  --passwordfile $GFCONF/pwd.conf $PORT undeploy  --target $INSTANCIA  $DEPLOYWEBATUAL"`"
                                 fi


                                if [ "$INSTATIVA" = "1"  ]
                                then
                                        echo
                                        echo "`date +%c` - Parando instancia $INSTANCIA"
					"`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin --passwordfile $GFCONF/pwd.conf $PORT stop-local-instance $INSTANCIA"`"
                                fi

				 echo
                                 echo "`date +%c` - Executando Deploy $APPWEBNOVA na instancia $INSTANCIA"
				
				CONTEXTCONC=`echo $APPSWEB | /bin/awk -F "-" '{print $1"-"$2}'`
				CONTEXTGUACAH=`echo $APPSWEB | /bin/awk -F "-" '{print $1}'`
                                if [ $CONTEXTCONC = "frontend-conciliacao" ]
                                then
					#NAMECONTEXT="--name  $APPSWEB-$VERSAONOVA-$AMBIENTE --contextroot frontend-conciliador"
					NAMECONTEXT="--name  $APPSWEB-$AMBIENTE  --contextroot frontend-conciliacao"

				elif [ $CONTEXTGUACAH = "guacah" ]
				then 
					NAMECONTEXT="--name  $APPSWEB-$AMBIENTE  --contextroot guacah"
                               	else
					#NAMECONTEXT="--name $APPSWEB-$VERSAONOVA-$AMBIENTE"
					NAMECONTEXT="--name $APPSWEB-$AMBIENTE"
                                fi

				  "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin  --passwordfile $GFCONF/pwd.conf $PORT deploy $NAMECONTEXT  --target $INSTANCIA  $PUBLICAHOME/$AMBIENTE/sgv/host/$APPWEBNOVA   "`"

#                                DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/find $GFHOME/domains/$DOMAIN/applications/__internal/$APPSWEB-$VERSAONOVA-$AMBIENTE/ -name '$APPSWEB*\.[ew]ar'"`
				 DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/ls $GFHOME/domains/$DOMAIN/applications/__internal/$APPSWEB-$AMBIENTE/'*\.[ew]ar'"`
                                 echo
                                 echo $DPLPUB

				 if [ "$DPLPUB" != "" ]
                                 then
                                        #echo
                                        #cho $DPLPUB
                                        echo
                                        echo "`date +%c` - Iniciando instancia $INSTANCIA"
					`$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin --passwordfile $GFCONF/pwd.conf $PORT start-local-instance --sync full $INSTANCIA "`

                                        #Checagem MD5 entre a publicacao a ser realizada e a publicada
                                        MD5DPLNOV=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $PUBLICAHOME/$AMBIENTE/sgv/host/$APPSWEB*" | /bin/awk -F " " '{print $1}'`
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
                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/host/$APPSWEB*"`"
#                                        echo
                                        echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                        "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/host/$APPSWEB*`"
#                                        echo

                                        else
						echo "Deploy nao realizado"
                                                `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA ERROR"`
                                                echo "`date +%c` - Removendo  deploy $SGVWEBNOVO remoto"
                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/host/$APPSWEB*"`"
                                                echo
                                                echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/host/$APPSWEB*`"
                                                `echo "" ` > "$PUBLICAHOME/PIDCONCHML.pid"
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
                                        `echo "" ` > "$PUBLICAHOME/PIDCONCHML.pid"
					`echo "" ` > "$PUBLICAHOME/PIDSGV.pid"
                                        PIDCONCHML=""
                                        exit 1;
				fi

                else
  	              echo "Publicacao em Andamento"
               	fi
        done

else

	echo "`date +%c` - Nao existem deploys de WEB para atualizar"
fi

