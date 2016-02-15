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
DOMAINS="domain1 domain2"

#Usuario Shell para conexao remota
USERSO=oracle
CMDUSER="su --login  $USERSO --command "
SISTEMA="SGV"

#-----------------------------WEB------------------------------------------------------------

PUBLICAHOME=/opt/publica
TODAY="`date +%Y%m%d`"
INST=01
HOMEPUBLICA=/opt/$APPAMBIENTE
STARTSGV=/opt/sgvhost.sh
#LOGS=/opt/deploys/log/"Publicacao-`date +%Y%m%d`.log"

#Armazenando logs
#exec >> $LOGS 2>&1

#Busca de Ambiente que existem aplicacoes a serem publicadas
PUBLICAWEB="`/bin/find "$PUBLICAHOME" -name "sgv-*" |  /bin/awk -F "/" '{print $4}' | /bin/egrep -o ^[A-Z]*| /usr/bin/uniq`"

PIDPUB=`ps ax | grep "deployintprdsgv.sh" | grep -v grep | awk -F " " '{print $1}'`	

#echo "Teste PID PUB : $PIDPUB"
#PIDSITUAT=" "
#PIDINT=" "
PIDINT="`cat $PUBLICAHOME/PIDINT.pid`"
PIDPRD="`cat $PUBLICAHOME/PIDPRD.pid`"


echo "o PID DO PUBLICADOR" $PIDPUB
echo "o PID INT EH " $PIDINT
echo "o PID PRD EH " $PIDPRD


ENVIAEMAIL="infra.java@redetendencia.com.br"


if [ "$PUBLICAWEB" != ""  ]
then
        for i in $PUBLICAWEB
        do
                AMBIENTE=${i}

		if  [ "$AMBIENTE" = "PRD" ] && [ "$PIDPRD" = "" ]
		then 
                        EXPURGO_LOGS=/opt/publica/log/"Publicacao-PRD-`date +%Y%m%d`.log"
			LOGS="/opt/publica/log/RelatorioPublica-WEB-PRD.log"
                        #Armazenando logs
                        exec > $LOGS 2>&1
                        echo $PIDPUB > $PUBLICAHOME/PIDPRD.pid
                        PIDPRD="`cat $PUBLICAHOME/PIDPRD.pid`"
			
                        #Verificando novos deploys
                        SGVWEBNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgv/web/" | grep sgv-ear | /bin/awk -F "-" '{print $0}'| /bin/sort | /usr/bin/tail -n1`"
                        SGVRELNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgv/web/" | grep sgv-relatorio | /bin/awk -F "-" '{print $0}'| /bin/sort | /usr/bin/tail -n1`"


			if [  "$SGVWEBNOVO" != "" ]
                        then
                                IP1="172.16.57.3"

                                echo
                                echo "`date +%c` ----INICIANDO COPIA EM PRODUCAO SGV WEB-------"
				#Criando pasta remota
				echo "`date +%c` - Criando pasta Remota"
				 "`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/mkdir -p  $PUBLICAHOME/$AMBIENTE/sgv/web/$TODAY"`"
				#Copiando arquivos para o servidor remoto
	       	                echo "`date +%c` - Copiando arquivos do ambiente $AMBIENTE-WEB para a pasta de publicacao"
	                        `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgv/web/sgv-ear*" $IP1:$PUBLICAHOME/$AMBIENTE/sgv/web/$TODAY/"`
				#Removendo Deploy apos copia
                                echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/web/sgv-ear*`"
				#Enviando Confirmacao da copia
                                echo "`date +%c` - Enviando confirmacao do deploy  SGV-PRD-WEB $SGVWEBNOVO "
				`$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php SGV-PRD-WEB $SGVWEBNOVO"`

                                echo "Expurgando LOGS"
                                `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                echo "Enviando Email de Publicacao"
                                echo "-----------------------------FIM--------------------------"
                                echo
	                        `/bin/echo | /bin/mail -s "Publicacao SGV-PRD-WEB $SGVWEBNOVO" -r "infra.java@redetendencia.com.br" -q $LOGS $ENVIAEMAIL`
                                echo


			fi		

			if [  "$SGVRELNOVO" != "" ]
			then
				IP1="172.16.57.6"

                                echo
                                echo "----INICIANDO COPIA EM PRODUCAO SGV RELATORIO-------"
                                #Criando pasta remota
                                echo "`date +%c` - Criando pasta Remota"
                                 "`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/mkdir -p  $PUBLICAHOME/$AMBIENTE/sgv/web/$TODAY"`"
                                #Copiando arquivos para o servidor remoto
                                echo "`date +%c` - Copiando arquivos do ambiente $AMBIENTE-WEB para a pasta de publicacao"
                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgv/web/sgv-relatorio*" $IP1:$PUBLICAHOME/$AMBIENTE/sgv/web/$TODAY/"`
                                #Removendo Deploy apos copia
                                echo "`date +%c` - Removendo deploy $SGVRELNOVO local"
                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/web/sgv-relatorio*`"
                                #Enviando Confirmacao da copia
                                echo "`date +%c` - Enviando confirmacao do deploy SGV-PRD-RELATORIO $SGVRELNOVO "
                               `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php SGV-PRD-RELATORIO $SGVRELNOVO"`

	                        echo "Expurgando LOGS"
        	                `/bin/cat $LOGS >> $EXPURGO_LOGS`
	
        	                echo "Enviando Email de Publicacao"
                	        echo "-----------------------------FIM--------------------------"
                        	echo
                       	`/bin/echo | /bin/mail -s "Publicacao SGV-PRD-RELATORIO $SGVRELNOVO" -r "infra.java@redetendencia.com.br" -q $LOGS $ENVIAEMAIL`
                                echo

			fi

                        `echo "" ` > "$PUBLICAHOME/PIDPRD.pid"	

 
                elif [ "$AMBIENTE" = "INT" ] && [ "$PIDINT" = "" ]
                then
                        EXPURGO_LOGS=/opt/publica/log/"Publicacao-INT-`date +%Y%m%d`.log"
			LOGS=/opt/publica/log/"Relatorio-WEB-INT.log"
#                        #Armazenando logs
                        exec > $LOGS 2>&1
                        echo $PIDPUB > $PUBLICAHOME/PIDINT.pid
                        PIDINT="`cat $PUBLICAHOME/PIDINT.pid`"
                        echo "o PID EH " $PIDINT
                        INSTHOME="/opt/glassfish3/glassfish/nodes/localhost-domain1"
                        GFCONF="/opt/glassfish3/glassfish/config"
                        #EXPURGOHOME=/opt/deploys/$AMBIENTE/sgv/"`date +%Y%m%d`"
                        #EXPURGOLOCAL="`ls -d  $EXPURGOHOME |grep -c $TODAY 2> /dev/null`"
                        #PORT="-p 4848"
                        PORT=""
                        DOMAIN="domain1"


                        #IPS DOS SERVIDOR DOS AMBIENTES INT
                        if [ "$AMBIENTE" = "INT"  ]
                        then
                                IP1="172.17.57.3"
                        fi


                        #Iniciando Dominio DAS

                        pid=`$CMDUSER "/usr/bin/ssh $IP1 -C ps ax | grep "$DOMAIN" | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                        if [ "$pid" != "" ]; then
                                echo
                                echo "`date +%c` - O Dominio $DOMAIN ESTA RODANDO NO PID $pid."
                                echo

                        else
                                echo
                                echo -n "`date +%c` - Iniciando Instancia $DOMAIN SGV: "
                                echo
                                 `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-domain $DOMAIN -W $GFCONF/pwd.conf"`
                                echo
                        fi



                        echo
                        echo "---------------Iniciando Publicacao $AMBIENTE-WEB-----------"
                        echo
                        echo "Publicando aplicacoes"
                        WEBS=`/bin/find "/opt/publica/INT/sgv" -name "sgv-*" |  /bin/awk -F "/" '{print $6}' | uniq`
                        echo "$WEBS"
                        echo "---------------------------------------------------------"

                        #Expurgo Local
                         #if [ "$EXPURGOLOCAL" != "1" ]
                         #then
                         #        echo "`date +%c` -  Criando pasta de Expurgo Local"
                         #       `$CMDUSER "/bin/mkdir -p $EXPURGOHOME"`
                         #fi

                         #Expurgo Remoto
                         #if [ "$EXPURGOREMOTO" != "1" ]
                         #then
                         #        echo "`date +%c` -  Criando pasta de Expurgo Remoto"
                         #        "`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/mkdir -p  $EXPURGOHOME"`"
                         #fi



                        for j in $WEBS
                        do
                                WEB=${j}
                                SGVWEBNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgv/$WEB/" | grep sgv- | /bin/awk -F "-" '{print $0}'| /bin/sort | /usr/bin/tail -n1`"

                                #SGVWEBNOVO="`/bin/ls "$PUBLICAHOME/$AMBIENTE/sgv/$WEB/" | grep sgv- | /bin/awk -F "-" '{print $0}'| /bin/sort`"
                                VERSAONOVA=`echo "$SGVWEBNOVO" |  /bin/awk -F "-" '{print $3}' | sed -e s'|.ear||'`

#                               if [ "$SGVWEBNOVO" != ""  ]
#                               then

                                echo "SGVWEBNOVO = $SGVWEBNOVO"

                               if [ "$SGVWEBNOVO" != "" ] && [ "$WEB" = "web1" ]
                                then
                                        for k in $SGVWEBNOVO
                                        do
                                                APPWEBNOVA=${k}
                                                APPSWEB=`echo ${k} |  /bin/awk -F "-" '{print $1"-"$2}'`
                                                INSTANCIA="INT01"

                                                if [ $APPSWEB = "sgv-relatorio" ]
                                                then
                                                        APP="RELATORIO1"
                                                else

                                                        APP=`echo "$WEB" | tr "a-z" "A-Z"`
                                                fi

                                                echo "var APPSWEB= "$APPSWEB
                                                echo
                                                DEPLOYWEBATUAL=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/ls $INSTHOME/$INSTANCIA/applications |grep "$APPSWEB""`
                                                echo "WEB ATUAL $DEPLOYWEBATUAL"
                                                echo "WEB NOVA $APPWEBNOVA"
                                                echo
                                                #Copiando Arquivos para deploy
                                                echo "Copiando arquivos do ambiente $AMBIENTE para a pasta de publicacao"
                                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*" $IP1:$PUBLICAHOME/$AMBIENTE/sgv/$WEB/"`
                                                echo

                                               #VERIFICANDO STATUS DA INSTANCIA
                                                INSTATIVA=`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin list-instances -W $GFCONF/pwd.conf $PORT|grep $INSTANCIA" |awk -F " " '{print $2}' | grep -c running`
                                                #echo $INSTATIVA
                                                #echo
                                                if [ "$INSTATIVA" = "1"  ]
                                                then
                                                        echo
                                                        echo "`date +%c` - Parando instancia $INSTANCIA"
#                                                        `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-local-instance $PORT --sync full $INSTANCIA  -W $GFCONF/pwd.conf"`
                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin stop-local-instance $PORT --kill true -W $GFCONF/pwd.conf $INSTANCIA"`"

                                                fi

                                                if [ "$DEPLOYWEBATUAL" != "" ]
                                                then
                                                        echo
                                                        echo "Executando UNDEPLOY na instancia $INSTANCIA"
                                                        echo "`date +%c` -  Executando Undeploy $DEPLOYWEBATUAL na instancia $INSTANCIA"

                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin undeploy $PORT -W $GFCONF/pwd.conf --target $INSTANCIA $DEPLOYWEBATUAL &"`"
                                                fi
                                                echo
                                                echo "`date +%c` - Executando Deploy $APPWEBNOVA na instancia $INSTANCIA"
                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin deploy $PORT --name $APPSWEB-$VERSAONOVA-$INSTANCIA --target $INSTANCIA -W $GFCONF/pwd.conf  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPWEBNOVA &"`"


                                                DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/find $GFHOME/domains/$DOMAIN/applications/__internal/$APPSWEB-$VERSAONOVA-$INSTANCIA/ -name '$APPSWEB*.ear'"` #| /bin/awk -F "/" '{print $1}'"
  						if [ "$DPLPUB" != "" ]
						then
						
							echo
							echo $DPLPUB
		 					echo
#							echo "`date +%c` - Parando Glassfish Apos Deploy"
#							"`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin stop-local-instance $PORT --kill true -W $GFCONF/pwd.conf $INSTANCIA"`"
#							sleep 3;
							#"`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/kill -9 $PID 2> /dev/null"`"
							echo
			   			  	echo "`date +%c` - Iniciando instancia $INSTANCIA"
							`$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-local-instance $PORT --sync full $INSTANCIA  -W $GFCONF/pwd.conf"`


							#Checagem MD5 entre a publicacao a ser realizada e a publicada
							MD5DPLNOV=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*" | /bin/awk -F " " '{print $1}'`
							echo "MD5 Deploy novo $MD5DPLNOV"
							MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $DPLPUB" | /bin/awk -F "/" '{print $1}'`
							echo "MD5 Deploy Publicado $MD5DPLPUB"
	
							if [ $MD5DPLNOV != $MD5DPLPUB ]
							then
								echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
								#exit 1;

							else
								echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
								echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA"
								`$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA"`
							fi


							echo
							#echo "`date +%c` - Removendo  deploy $APPWEBNOVA remoto"
							#"`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*"`"
							echo
							echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
							 "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*`"

	#                                               echo "`date +%c` - Expurgando deploy $SGVWEBNOVO remoto"
	#                                               "`$CMDUSER "/usr/bin/ssh $IP1 -C mv  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/sgv-ear* $EXPURGOHOME"`"
	#                                               echo
	#                                               echo "`date +%c` - Expurgando deploy $SGVWEBNOVO local"
	#                                                "`mv  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/sgv-ear* $EXPURGOHOME`"

							echo
							echo "-----------------------------FIM--------------------------"

							else
								echo "Deploy nao realizado"
								`$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA ERROR"`
								echo "`date +%c` - Removendo  deploy $SGVWEBNOVO remoto"
								"`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*"`"
								echo
								echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
								"`rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*`"
								`echo "" ` > "$PUBLICAHOME/PIDINT.pid"
								echo
								echo "-----------------------------FIM--------------------------"
								##exit 1;
							fi
                                        done
                                        `echo "" ` > "$PUBLICAHOME/PIDINT.pid"
                                         PIDINT=""

                                       `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                        echo "Enviando Email de Publicacao"
                                        echo "-----------------------------FIM--------------------------"
                                        echo

                                       `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA" -r "infra.java@redetendencia.com.br" -q $LOGS $ENVIAEMAIL`


					 ##exit 1;
                                

                               elif [ "$SGVWEBNOVO" != "" ] && [ "$WEB" = "web2" ]
                               then
                                        for k in $SGVWEBNOVO
                                        do
                                                APPWEBNOVA=${k}
                                                APPSWEB=`echo ${k} |  /bin/awk -F "-" '{print $1"-"$2}'`
                                                INSTANCIA="INT02"

                                                if [ $APPSWEB = "sgv-relatorio" ]
                                                then
                                                        APP="RELATORIO2"
                                                else

                                                        APP=`echo "$WEB" | tr "a-z" "A-Z"`
                                                fi

                                                echo "var APPSWEB= "$APPSWEB
                                                echo
                                                DEPLOYWEBATUAL=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/ls $INSTHOME/$INSTANCIA/applications |grep "$APPSWEB""`
                                                echo "WEB ATUAL $DEPLOYWEBATUAL"
                                                echo "WEB NOVA $APPWEBNOVA"
                                                echo
                                                #Copiando Arquivos para deploy
                                                echo "Copiando arquivos do ambiente $AMBIENTE para a pasta de publicacao"
                                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*" $IP1:$PUBLICAHOME/$AMBIENTE/sgv/$WEB/"`
                                                echo

                                               #VERIFICANDO STATUS DA INSTANCIA
                                                INSTATIVA=`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin list-instances -W $GFCONF/pwd.conf $PORT|grep $INSTANCIA" |awk -F " " '{print $2}' | grep -c running`
                                                #echo $INSTATIVA
                                                #echo
                                                if [ "$INSTATIVA" = "1"  ]
                                                then
                                                        echo
                                                        echo "`date +%c` - Parando instancia $INSTANCIA"
#                                                        `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-local-instance $PORT --sync full $INSTANCIA  -W $GFCONF/pwd.conf"`
                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin stop-local-instance $PORT --kill true -W $GFCONF/pwd.conf $INSTANCIA"`"
                                                fi

                                                if [ "$DEPLOYWEBATUAL" != "" ]
                                                then
                                                        echo
                                                        echo "Executando UNDEPLOY na instancia $INSTANCIA"
                                                        echo "`date +%c` -  Executando Undeploy $DEPLOYWEBATUAL na instancia $INSTANCIA"

                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin undeploy $PORT -W $GFCONF/pwd.conf --target $INSTANCIA $DEPLOYWEBATUAL &"`"
                                                fi
                                                echo
                                                echo "`date +%c` - Executando Deploy $APPWEBNOVA na instancia $INSTANCIA"
                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin deploy $PORT --name $APPSWEB-$VERSAONOVA-$INSTANCIA --target $INSTANCIA -W $GFCONF/pwd.conf  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPWEBNOVA &"`"


                                                DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/find $GFHOME/domains/$DOMAIN/applications/__internal/$APPSWEB-$VERSAONOVA-$INSTANCIA/ -name '$APPSWEB*.ear'"` #| /bin/awk -F "/" '{print $1}'"
                                                if [ "$DPLPUB" != "" ]
                                                then

                                                        echo
                                                        echo $DPLPUB
                                                        echo
#                                                        echo "`date +%c` - Parando Glassfish Apos Deploy"
#                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin stop-local-instance $PORT --kill true -W $GFCONF/pwd.conf $INSTANCIA"`"
#                                                        sleep 3;
                                                        #"`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/kill -9 $PID 2> /dev/null"`"
                                                        echo
                                                        echo "`date +%c` - Iniciando instancia $INSTANCIA"
                                                        `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-local-instance $PORT --sync full $INSTANCIA  -W $GFCONF/pwd.conf"`


                                                        #Checagem MD5 entre a publicacao a ser realizada e a publicada
                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*" | /bin/awk -F " " '{print $1}'`
                                                        echo "MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $DPLPUB" | /bin/awk -F "/" '{print $1}'`
                                                        echo "MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
                                                                #exit 1;

                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
                                                                echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA"
                                                                `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA"`
                                                        fi


                                                        echo
                                                        echo "`date +%c` - Removendo  deploy $APPWEBNOVA remoto"
                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*"`"
                                                        echo
                                                        echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                                         "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*`"

        #                                               echo "`date +%c` - Expurgando deploy $SGVWEBNOVO remoto"
        #                                               "`$CMDUSER "/usr/bin/ssh $IP1 -C mv  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/sgv-ear* $EXPURGOHOME"`"
        #                                               echo
        #                                               echo "`date +%c` - Expurgando deploy $SGVWEBNOVO local"
        #                                                "`mv  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/sgv-ear* $EXPURGOHOME`"

                                                        echo
                                                        echo "-----------------------------FIM--------------------------"

                                                        else
                                                                echo "Deploy nao realizado"
                                                                `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA ERROR"`
                                                                echo "`date +%c` - Removendo  deploy $SGVWEBNOVO remoto"
                                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*"`"
                                                                echo
                                                                echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*`"
                                                                `echo "" ` > "$PUBLICAHOME/PIDINT.pid"
                                                                echo
                                                                echo "-----------------------------FIM--------------------------"
                                                                #exit 1;
                                                        fi
                                        done
                                        `echo "" ` > "$PUBLICAHOME/PIDINT.pid"
                                        PIDINT=""

                                       `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                        echo "Enviando Email de Publicacao"
                                        echo "-----------------------------FIM--------------------------"
                                        echo

                                       `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA" -r "infra.java@redetendencia.com.br" -q $LOGS $ENVIAEMAIL`


                               		#exit 1;
										
                               elif [ "$SGVWEBNOVO" != "" ] && [ "$WEB" = "web3" ]
                               then
                                        for k in $SGVWEBNOVO
                                        do
                                                APPWEBNOVA=${k}
                                                APPSWEB=`echo ${k} |  /bin/awk -F "-" '{print $1"-"$2}'`
                                                INSTANCIA="INT03"

                                                if [ $APPSWEB = "sgv-relatorio" ]
                                                then
                                                        APP="RELATORIO3"
                                                else

                                                        APP=`echo "$WEB" | tr "a-z" "A-Z"`
                                                fi

                                                echo "var APPSWEB= "$APPSWEB
                                                echo
                                                DEPLOYWEBATUAL=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/ls $INSTHOME/$INSTANCIA/applications |grep "$APPSWEB""`
                                                echo "WEB ATUAL $DEPLOYWEBATUAL"
                                                echo "WEB NOVA $APPWEBNOVA"
                                                echo
                                                #Copiando Arquivos para deploy
                                                echo "Copiando arquivos do ambiente $AMBIENTE para a pasta de publicacao"
                                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*" $IP1:$PUBLICAHOME/$AMBIENTE/sgv/$WEB/"`
                                                echo

                                               #VERIFICANDO STATUS DA INSTANCIA
                                                INSTATIVA=`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin list-instances -W $GFCONF/pwd.conf $PORT|grep $INSTANCIA" |awk -F " " '{print $2}' | grep -c running`
                                                #echo $INSTATIVA
                                                #echo
                                                if [ "$INSTATIVA" = "1"  ]
                                                then
                                                        echo
                                                        echo "`date +%c` - Parando instancia $INSTANCIA"
#                                                        `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-local-instance $PORT --sync full $INSTANCIA  -W $GFCONF/pwd.conf"`
                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin stop-local-instance $PORT --kill true -W $GFCONF/pwd.conf $INSTANCIA"`"
                                                fi

                                                if [ "$DEPLOYWEBATUAL" != "" ]
                                                then
                                                        echo
                                                        echo "Executando UNDEPLOY na instancia $INSTANCIA"
                                                        echo "`date +%c` -  Executando Undeploy $DEPLOYWEBATUAL na instancia $INSTANCIA"

                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin undeploy $PORT -W $GFCONF/pwd.conf --target $INSTANCIA $DEPLOYWEBATUAL &"`"
                                                fi
                                                echo
                                                echo "`date +%c` - Executando Deploy $APPWEBNOVA na instancia $INSTANCIA"
                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin deploy $PORT --name $APPSWEB-$VERSAONOVA-$INSTANCIA --target $INSTANCIA -W $GFCONF/pwd.conf  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPWEBNOVA &"`"


                                                DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/find $GFHOME/domains/$DOMAIN/applications/__internal/$APPSWEB-$VERSAONOVA-$INSTANCIA/ -name '$APPSWEB*.ear'"` #| /bin/awk -F "/" '{print $1}'"
                                                if [ "$DPLPUB" != "" ]
                                                then

                                                        echo
                                                        echo $DPLPUB
                                                        echo
#                                                        echo "`date +%c` - Parando Glassfish Apos Deploy"
#                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin stop-local-instance $PORT --kill true -W $GFCONF/pwd.conf $INSTANCIA"`"
#                                                        sleep 3;
                                                        #"`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/kill -9 $PID 2> /dev/null"`"
                                                        echo
                                                        echo "`date +%c` - Iniciando instancia $INSTANCIA"
                                                        `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-local-instance $PORT --sync full $INSTANCIA  -W $GFCONF/pwd.conf"`


                                                        #Checagem MD5 entre a publicacao a ser realizada e a publicada
                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*" | /bin/awk -F " " '{print $1}'`
                                                        echo "MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $DPLPUB" | /bin/awk -F "/" '{print $1}'`
                                                        echo "MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
                                                                #exit 1;

                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
                                                                echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA"
                                                                `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA"`
                                                        fi


                                                        echo
                                                        echo "`date +%c` - Removendo  deploy $APPWEBNOVA remoto"
                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*"`"
                                                        echo
                                                        echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                                         "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*`"

        #                                               echo "`date +%c` - Expurgando deploy $SGVWEBNOVO remoto"
        #                                               "`$CMDUSER "/usr/bin/ssh $IP1 -C mv  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/sgv-ear* $EXPURGOHOME"`"
        #                                               echo
        #                                               echo "`date +%c` - Expurgando deploy $SGVWEBNOVO local"
        #                                                "`mv  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/sgv-ear* $EXPURGOHOME`"

                                                        echo
                                                        echo "-----------------------------FIM--------------------------"

                                                        else
                                                                echo "Deploy nao realizado"
                                                                `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA ERROR"`
                                                                echo "`date +%c` - Removendo  deploy $SGVWEBNOVO remoto"
                                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*"`"
                                                                echo
                                                                echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*`"
                                                                `echo "" ` > "$PUBLICAHOME/PIDINT.pid"
                                                                echo
                                                                echo "-----------------------------FIM--------------------------"
                                                                #exit 1;
                                                        fi
                                        done
                                        `echo "" ` > "$PUBLICAHOME/PIDINT.pid"
                                        PIDINT=""

                                       `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                        echo "Enviando Email de Publicacao"
                                        echo "-----------------------------FIM--------------------------"
                                        echo

                                       `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA" -r "infra.java@redetendencia.com.br" -q $LOGS $ENVIAEMAIL`


					#exit 1;

                               elif [ "$SGVWEBNOVO" != "" ] && [ "$WEB" = "web4" ]
                               then
                                        for k in $SGVWEBNOVO
                                        do
                                                APPWEBNOVA=${k}
                                                APPSWEB=`echo ${k} |  /bin/awk -F "-" '{print $1"-"$2}'`
                                                INSTANCIA="INT04"

                                                if [ $APPSWEB = "sgv-relatorio" ]
                                                then
                                                        APP="RELATORIO4"
                                                else

                                                        APP=`echo "$WEB" | tr "a-z" "A-Z"`
                                                fi

                                                echo "var APPSWEB= "$APPSWEB
                                                echo
                                                DEPLOYWEBATUAL=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/ls $INSTHOME/$INSTANCIA/applications |grep "$APPSWEB""`
                                                echo "WEB ATUAL $DEPLOYWEBATUAL"
                                                echo "WEB NOVA $APPWEBNOVA"
                                                echo
                                                #Copiando Arquivos para deploy
                                                echo "Copiando arquivos do ambiente $AMBIENTE para a pasta de publicacao"
                                                `$CMDUSER "/usr/bin/scp  "$PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*" $IP1:$PUBLICAHOME/$AMBIENTE/sgv/$WEB/"`
                                                echo

                                               #VERIFICANDO STATUS DA INSTANCIA
                                                INSTATIVA=`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin list-instances -W $GFCONF/pwd.conf $PORT|grep $INSTANCIA" |awk -F " " '{print $2}' | grep -c running`
                                                #echo $INSTATIVA
                                                #echo
                                                if [ "$INSTATIVA" = "1"  ]
                                                then
                                                        echo
                                                        echo "`date +%c` - Parando instancia $INSTANCIA"
#                                                        `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-local-instance $PORT --sync full $INSTANCIA  -W $GFCONF/pwd.conf"`
                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin stop-local-instance $PORT --kill true -W $GFCONF/pwd.conf $INSTANCIA"`"
                                                fi

                                                if [ "$DEPLOYWEBATUAL" != "" ]
                                                then
                                                        echo
                                                        echo "Executando UNDEPLOY na instancia $INSTANCIA"
                                                        echo "`date +%c` -  Executando Undeploy $DEPLOYWEBATUAL na instancia $INSTANCIA"

                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin undeploy $PORT -W $GFCONF/pwd.conf --target $INSTANCIA $DEPLOYWEBATUAL &"`"
                                                fi
                                                echo
                                                echo "`date +%c` - Executando Deploy $APPWEBNOVA na instancia $INSTANCIA"
                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin deploy $PORT --name $APPSWEB-$VERSAONOVA-$INSTANCIA --target $INSTANCIA -W $GFCONF/pwd.conf  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPWEBNOVA &"`"


                                                DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/find $GFHOME/domains/$DOMAIN/applications/__internal/$APPSWEB-$VERSAONOVA-$INSTANCIA/ -name '$APPSWEB*.ear'"` #| /bin/awk -F "/" '{print $1}'"
                                                if [ "$DPLPUB" != "" ]
                                                then

                                                        echo
                                                        echo $DPLPUB
                                                        echo
#                                                        echo "`date +%c` - Parando Glassfish Apos Deploy"
#                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C $GFHOME/bin/asadmin stop-local-instance $PORT --kill true -W $GFCONF/pwd.conf $INSTANCIA"`"
#                                                        sleep 3;
                                                        #"`$CMDUSER "/usr/bin/ssh $IP1 -C /bin/kill -9 $PID 2> /dev/null"`"
                                                        echo
                                                        echo "`date +%c` - Iniciando instancia $INSTANCIA"
                                                        `$CMDUSER "/usr/bin/ssh $IP1 -C  $GFHOME/bin/asadmin start-local-instance $PORT --sync full $INSTANCIA  -W $GFCONF/pwd.conf"`


                                                        #Checagem MD5 entre a publicacao a ser realizada e a publicada
                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*" | /bin/awk -F " " '{print $1}'`
                                                        echo "MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $IP1 -C /usr/bin/md5sum $DPLPUB" | /bin/awk -F "/" '{print $1}'`
                                                        echo "MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
                                                                #exit 1;

                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
                                                                echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA"
                                                                `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA"`
								#"`/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA`"
                                                        fi


                                                        echo
                                                        echo "`date +%c` - Removendo  deploy $APPWEBNOVA remoto"
                                                        "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*"`"
                                                        echo
                                                        echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                                         "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*`"

        #                                               echo "`date +%c` - Expurgando deploy $SGVWEBNOVO remoto"
        #                                               "`$CMDUSER "/usr/bin/ssh $IP1 -C mv  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/sgv-ear* $EXPURGOHOME"`"
        #                                               echo
        #                                               echo "`date +%c` - Expurgando deploy $SGVWEBNOVO local"
        #                                                "`mv  $PUBLICAHOME/$AMBIENTE/sgv/$WEB/sgv-ear* $EXPURGOHOME`"

                                                        echo
                                                        echo "-----------------------------FIM--------------------------"

                                                        else
                                                                echo "Deploy nao realizado"
                                                                `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$APP $APPWEBNOVA ERROR"`
                                                                echo "`date +%c` - Removendo  deploy $SGVWEBNOVO remoto"
                                                                "`$CMDUSER "/usr/bin/ssh $IP1 -C rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*"`"
                                                                echo
                                                                echo "`date +%c` - Removendo deploy $SGVWEBNOVO local"
                                                                "`rm -f $PUBLICAHOME/$AMBIENTE/sgv/$WEB/$APPSWEB*`"
                                                                `echo "" ` > "$PUBLICAHOME/PIDINT.pid"
                                                                echo
                                                                echo "-----------------------------FIM--------------------------"
                                                                #exit 1;
                                                        fi
                                        done
                                        `echo "" ` > "$PUBLICAHOME/PIDINT.pid"
                                        PIDINT=""

                                         echo "Expurgando LOGS"
                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                        echo "Enviando Email de Publicacao"
                                        echo "-----------------------------FIM--------------------------"
                                        echo

                                       `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA" -r "infra.java@redetendencia.com.br" -q $LOGS $ENVIAEMAIL`


					#exit 1;

                              else
					echo "Erro ao fazer o deploy" 

                              fi
										
                        done

                else
  	              echo "Publicacao em Andamento"
               	fi
        done

else

	echo "`date +%c` - Nao existem deploys de WEB para atualizar"
fi

