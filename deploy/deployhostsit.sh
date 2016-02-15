#!/bin/bash

#
# chkconfig: 35 80 05
# description: Deploy script for HOSTS Tendencia
# Autor: Bruno de Abreu Caceres
# Data: Abr/2014

#exec >> /opt/publica/log/Publicacao.log 2>&1

#Variaveis Glassfish e Oracle

JAVA_HOME=/opt/jdk1.6.0_45
JDK_HOME=$JAVA_HOME
CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar:
export ORACLE_HOME=/opt/oracle/product/11.2/client
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
PATH=$ORACLE_HOME/bin:$JAVA_HOME/bin:$PATH
export JDK_HOME JAVA_HOME CLASSPATH

#Usuario Shell para conexao remota
USERSO=oracle
CMDUSER="su --login  $USERSO --command "
#CMDUSER=" "
SISTEMA="SGV"

ENVIAEMAIL="infra.java@redetendencia.com.br"

#-----------------------------WEB------------------------------------------------------------

PUBLICAHOME=/opt/publica
TODAY="`date +%Y%m%d`"

#Buscando os arquivos de publicacao mais recentes
PUBLICAWEB="`/bin/find "$PUBLICAHOME" -name "sgv-*" |  /bin/awk -F "/" '{print $4}' | /bin/egrep -o ^[A-Z]*| /usr/bin/uniq`"

#-----------------------------HOST------------------------------------------------------------

#Servidores e seus aplicativos
SERVERS="sa-switch sa-pdvcel"
SERVER1="sa-am"
SERVER2="sa-online-v"
SERVER3="sa-am-tef sa-ttef sa-itautec sa-x25"
SERVER4="sa-pin sa-complementar sa-credito sa-fisico sa-assetur sa-blackhawk"
SERVER5="sa-oper sa-ask"
SERVER6="sa-sptrans sa-f3m sa-riocard sa-sfa sa-pop sa-acessocard sa-redetrans"
SERVERM="sa-mux sa-servcel sa-mfs"

#Variaveis de publicacao e expurgo local e remoto
UPLOADPUBLICA=/opt/publica
TODAY="`date +%Y%m%d`"
INST=01
HOMEPUBLICA=/opt/$APPAMBIENTE
STARTSGV=/opt/publica/sgvhost.sh
EXPURGO_LOGS=/opt/publica/log/"Publicacao-HOSTSIT-`date +%Y%m%d`.log"
LOGS=/opt/publica/log/"RelatorioPublicaHost.log"

#Armazenando logs
exec > $LOGS 2>&1

#Busca de Ambiente que existem aplicacoes a serem publicadas
PUBLICAHOST="`/bin/find "$UPLOADPUBLICA" -name "sa-*" |  /bin/awk -F "/" '{print $4}' | /bin/egrep -o ^[A-Z]*| /usr/bin/uniq`"

PIDPUB=`ps ax | grep "/opt/publica/deployhostsit.sh" | grep -v grep | awk -F " " '{print $1}'`

#echo "Teste PID PUB : $PIDPUB"
#PIDSITUAT=" "
#PIDINT=" "
PIDSITUATINT="`cat $PUBLICAHOME/PIDSITHOST.pid 2> /dev/null `"




if [ "$PUBLICAHOST" != ""  ]
then
        for i in $PUBLICAHOST
        do
                AMBIENTE=${i}
                if [ "$AMBIENTE" = "SIT" ] || [ "$AMBIENTE" = "UAT" ] || [ "$AMBIENTE" = "INT" ] && [ "$PIDSITUATINT" = "" ]
                then
                        APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                        APPSPUBLICA="`/bin/ls "$UPLOADPUBLICA/$AMBIENTE/sgv/host/" | grep sa- |   /bin/awk -F "-" '{print $0}' `"
                        HOMEPUBLICA=/opt/$APPAMBIENTE

                        #Armazenando logs
                        #exec >> $LOGS 2>&1
			#exec `tee /opt/publica/log/RelatorioPublicaHost.log` 2>&1 >> $LOGS
                        echo $PIDPUB > $PUBLICAHOME/PIDSITHOST.pid
                        PIDSITUAT="`cat $PUBLICAHOME/PIDSITHOST.pid`"
			echo "Projetos relacionados na publicacao"
			/bin/cat /opt/git/repo/host/MANIFEST
 			echo
			echo "APPSPUBLICA= $APPSPUBLICA"
#                        EXPURGOHOME=/opt/deploys/$AMBIENTE/sgv/"`date +%Y%m%d`"
#                        EXPURGOLOCAL="`ls -d  $EXPURGOHOME |grep -c $TODAY 2> /dev/null`"
                        #LOGS=/opt/deploys/log/"Publicacao-`date +%Y%m%d`.log"

                        #Armazenando logs
                        #exec >> $LOGS 2>&1

                        #Expurgo Local
#                         if [ "$EXPURGOLOCAL" != "1" ]
#                         then
#                                 echo "`date +%c` -  Criando pasta de Expurgo Local"
#                                `$CMDUSER "/bin/mkdir -p $EXPURGOHOME"`
#                         fi

                        #IPS DOS SERVIDORES DOS AMBIENTES SIT UAT
                        if [ "$AMBIENTE" = "SIT"  ]
                        then
                                HOSTS="172.17.58.11"
                                HOST1="172.17.52.11"
                                HOST2="172.17.52.12"
                                HOST3="172.17.52.13"
                                HOST4="172.17.52.14"
                                HOST5="172.17.52.15"
                                HOST6="172.17.52.16"
                                HOSTM="172.17.51.11"

                        elif [ "$AMBIENTE" = "INT"  ]
                        then
                                HOSTS="172.17.58.11"
                                HOST1="172.17.52.11"
                                HOST2="172.17.52.12"
                                HOST3="172.17.52.13"
                                HOST4="172.17.52.14"
                                HOST5="172.17.52.15"
                                HOST6="172.17.52.16"
                                HOSTM="172.17.51.11"


                        elif  [ "$AMBIENTE" = "UAT"  ]
                        then
                                HOSTS="172.17.58.11"
                                HOST1="172.17.52.11"
                                HOST2="172.17.52.12"
                                HOST3="172.17.52.13"
                                HOST4="172.17.52.14"
                                HOST5="172.17.52.15"
                                HOST6="172.17.52.16"
                                HOSTM="172.17.51.11"
                        else
                                echo "Ambiente Invalido"
                                exit 1;
                        fi

                        echo
                        echo "---------------Iniciando Publicacao $AMBIENTE-HOST-----------"
                        echo
                                echo "Publicando aplicacoes"
                                echo "$APPSPUBLICA"
                                echo "---------------------------------------------------------"

                        for j in $APPSPUBLICA
                        do
                                APPNAME="`echo ${j} | /bin/awk -F "-" '{if ($3 == "tef" || $3 == "v" ) {print$1"-"$2"-"$3;}else{print$1"-"$2};}'`"
                                APP="`echo ${j} | /bin/awk -F "-" '{if ($3 == "tef" || $3 == "v" ) {print$2"-"$3;}else{print$2};}'`"
                                ENVIAAPP="`echo ${j} | /bin/awk -F "-" '{if ($3 == "tef" ) {print$2$3;}else{print$2};}'| /usr/bin/tr '[:lower:]' '[:upper:]'`"


                                #PUBLICADOR DO SWITCH E PDVCEL
                                for k in $SERVERS
                                do
                                        if [  $k = $APPNAME ]
                                        then
		        	               APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
			                       HOMEPUBLICA=/opt/$APPAMBIENTE

                                               echo "`date +%c` -  Iniciando publicacao do server $HOSTS - $APPNAME - $AMBIENTE"
                                               echo "`date +%c` - Removendo deploy anterior da $APPNAME remota"
                                               "`$CMDUSER "/usr/bin/ssh $HOSTS -C rm -f $HOMEPUBLICA/$APPNAME*bin"`"

                                               echo "`date +%c` -  Copiando binario ${j} para a pasta de publicacao"
                                               `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $HOSTS:$HOMEPUBLICA"`

                                               #Verificando PID da APP a ser publicada
                                               PID=`$CMDUSER "/usr/bin/ssh $HOSTS -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                                                if [ "$PID" != "" ]
                                                then
                                                        echo "`date +%c` - Parando aplicacao $APPNAME"
                                                        `$CMDUSER "/usr/bin/ssh $HOSTS -C kill -9 $PID 2> /dev/null"`
                                                        `$CMDUSER "/usr/bin/ssh $HOSTS -C rm -f /var/run/$APP$INST-$APPAMBIENTE.pid"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME ja esta parada"
                                                fi

                                                echo "`date +%c` -  Publicando aplicacao"
                                                `$CMDUSER "/usr/bin/ssh $HOSTS -C $HOMEPUBLICA/$j $HOMEPUBLICA $HOMEPUBLICA/conf/$APPNAME-ATUAL.properties"`
                                                echo
                                                echo "`date +%c` -  Publicacao  $APPNAME instalada no ambiente $AMBIENTE"

                                                echo
                                                echo "`date +%c` - Removendo deploy $APPNAME local"
                                                "`rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j`"

#                                               echo "`date +%c` - Removendo deploy $APPNAME remoto"
#                                               "`$CMDUSER "/usr/bin/ssh $HOSTS -C rm -f $HOMEPUBLICA/$j"`"
                                                echo

                                                echo "`date +%c` -  Iniciando $APPNAME"
                                                `$CMDUSER "/usr/bin/ssh $HOSTS -C $STARTSGV $APP $APPAMBIENTE start"`
                                                 #Verificando se aplicacao esta ativa apos deploy
                                                 sleep 5
                                                 NOVOPID=`$CMDUSER "/usr/bin/ssh $HOSTS -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`
                                                  PIDRUN=`$CMDUSER "/usr/bin/ssh $HOSTS -C cat /var/run/$APP$INST-$APPAMBIENTE.pid"`

                                                if [ "$NOVOPID" = "" ] && [ "$PIDRUN" != "$NOVOPID" ]
                                                then
                                                        echo "`date +%c` - A aplicacao $APPNAME nao esta subindo ou existe um pid antigo interrompendo a aplicacao"
                                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j ERROR"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME subiu com sucesso"
                                                        echo "Teste com o nome da app - $SISTEMA-$AMBIENTE-$ENVIAAPP $j"
                                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j"`

		                                         echo "Expurgando LOGS"
                		                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                		        echo "Enviando Email de Publicacao"
		                                        echo "-----------------------------FIM--------------------------"
                		                        echo
                                                        `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br"  -q $LOGS $ENVIAEMAIL`
                                                fi

                                                echo
                                                echo "-----------------------------FIM--------------------------"

                                         fi

                                done

                                # PUBLICADOR DO AUTORIZADOR
                                for k in $SERVER1
                                do

                                        if [  $k = $APPNAME ]
                                        then
                                               APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                               HOMEPUBLICA=/opt/$APPAMBIENTE

                                               echo "`date +%c` -  Iniciando publicacao do server $HOST1 - $APPNAME - $AMBIENTE"
                                               echo "`date +%c` - Removendo deploy anterior da $APPNAME remota"
                                               "`$CMDUSER "/usr/bin/ssh $HOST1 -C rm -f $HOMEPUBLICA/$APPNAME*bin"`"

                                               echo "`date +%c` -  Copiando binario ${j} para a pasta de publicacao"
                                               `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $HOST1:$HOMEPUBLICA"`

                                               #Verificando PID da APP a ser publicada
                                               PID=`$CMDUSER "/usr/bin/ssh $HOST1 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                                                if [ "$PID" != "" ]
                                                then
                                                        echo "`date +%c` - Parando aplicacao $APPNAME"
                                                        `$CMDUSER "/usr/bin/ssh $HOST1 -C kill -9 $PID 2> /dev/null"`
                                                        `$CMDUSER "/usr/bin/ssh $HOST1 -C rm -f /var/run/$APP$INST-$APPAMBIENTE.pid"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME ja esta parada"
                                                fi

                                                echo "`date +%c` -  Publicando aplicacao"
                                                `$CMDUSER "/usr/bin/ssh $HOST1 -C $HOMEPUBLICA/$j $HOMEPUBLICA $HOMEPUBLICA/conf/$APPNAME-ATUAL.properties"`
                                                echo
                                                echo "`date +%c` -  Publicacao  $APPNAME instalada no ambiente $AMBIENTE"

                                                #Removendo os arquivos instalados
                                                echo
                                                echo "`date +%c` - Removendo deploy $APPNAME local"
                                                "`rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j`"

#                                                echo "`date +%c` - Removendo deploy $APPNAME remoto"
#                                                "`$CMDUSER "/usr/bin/ssh $HOST1 -C rm -f $HOMEPUBLICA/$j"`"
                                                echo

                                                echo "`date +%c` -  Iniciando $APPNAME"
                                                `$CMDUSER "/usr/bin/ssh $HOST1 -C $STARTSGV $APP $APPAMBIENTE start"`

                                                 #Verificando se aplicacao esta ativa apos deploy
                                                 sleep 5
                                                 NOVOPID=`$CMDUSER "/usr/bin/ssh $HOST1 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`
                                                  PIDRUN=`$CMDUSER "/usr/bin/ssh $HOST1 -C cat /var/run/$APP$INST-$APPAMBIENTE.pid"`

                                                if [ "$NOVOPID" = "" ] && [ "$PIDRUN" != "$NOVOPID" ]
                                                then
                                                        echo "`date +%c` - A aplicacao $APPNAME nao esta subindo ou existe um pid antigo interrompendo a aplicacao"
                                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j ERROR"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME subiu com sucesso"
                                                        echo "Teste com o nome da app - $SISTEMA-$AMBIENTE-$ENVIAAPP $j"
                                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j"`


                                                         echo "Expurgando LOGS"
                                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                                        echo "Enviando Email de Publicacao"
                                                        echo "-----------------------------FIM--------------------------"
                                                        echo
                                                        `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br"  -q $LOGS $ENVIAEMAIL`

                                                fi

                                                echo
                                                echo "-----------------------------FIM--------------------------"

                                         fi

                                done

                                #PUBLICADOR DO ONLINE-V
                                for k in $SERVER2
                                do
                                        if [  $k = $APPNAME ]
                                        then
                                               APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                               HOMEPUBLICA=/opt/$APPAMBIENTE

                                               echo "`date +%c` -  Iniciando publicacao do server $HOST2 - $APPNAME - $AMBIENTE"
                                               echo "`date +%c` - Removendo deploy anterior da $APPNAME remota"
                                               "`$CMDUSER "/usr/bin/ssh $HOST2 -C rm -f $HOMEPUBLICA/$APPNAME*bin"`"

                                               echo "`date +%c` -  Copiando binario ${j} para a pasta de publicacao"
                                               `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $HOST2:$HOMEPUBLICA"`

                                               #Verificando PID da APP a ser publicada
                                               PID=`$CMDUSER "/usr/bin/ssh $HOST2 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                                                if [ "$PID" != "" ]
                                                then
                                                        echo "`date +%c` - Parando aplicacao $APPNAME"
                                                        `$CMDUSER "/usr/bin/ssh $HOST2 -C kill -9 $PID 2> /dev/null"`
                                                        `$CMDUSER "/usr/bin/ssh $HOST2 -C rm -f /var/run/$APP$INST-$APPAMBIENTE.pid"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME ja esta parada"
                                                fi

                                                echo "`date +%c` -  Publicando aplicacao"
                                                `$CMDUSER "/usr/bin/ssh $HOST2 -C $HOMEPUBLICA/$j $HOMEPUBLICA $HOMEPUBLICA/conf/$APPNAME-ATUAL.properties"`
                                                echo
                                                echo "`date +%c` -  Publicacao  $APPNAME instalada no ambiente $AMBIENTE"

                                                echo
                                                echo "`date +%c` - Removendo deploy $APPNAME local"
                                                "`rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j`"

#                                                echo "`date +%c` - Removendo deploy $APPNAME remoto"
#                                                "`$CMDUSER "/usr/bin/ssh $HOST2 -C rm -f $HOMEPUBLICA/$j"`"
                                                echo
                                                echo "`date +%c` -  Iniciando $APPNAME"
                                                `$CMDUSER "/usr/bin/ssh $HOST2 -C $STARTSGV $APP $APPAMBIENTE start"`

                                                 #Verificando se aplicacao esta ativa apos deploy
                                                 sleep 5
                                                 NOVOPID=`$CMDUSER "/usr/bin/ssh $HOST2 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`
                                                 PIDRUN=`$CMDUSER "/usr/bin/ssh $HOST2 -C cat /var/run/$APP$INST-$APPAMBIENTE.pid"`

                                                if [ "$NOVOPID" = "" ] && [ "$PIDRUN" != "$NOVOPID" ]
                                                then
                                                        echo "`date +%c` - A aplicacao $APPNAME nao esta subindo ou existe um pid antigo interrompendo a aplicacao"
                                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j ERROR"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME subiu com sucesso"
                                                        echo "Teste com o nome da app - $SISTEMA-$AMBIENTE-$ENVIAAPP $j"
                                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j"`


                                                         echo "Expurgando LOGS"
                                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                                        echo "Enviando Email de Publicacao"
                                                        echo "-----------------------------FIM--------------------------"
                                                        echo
                                                        `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br"  -q $LOGS $ENVIAEMAIL`

                                                fi

                                                echo
                                                echo "-----------------------------FIM--------------------------"

                                         fi

                                done

                                #PUBLICADOR DOS TEFs AM-TEF, ITAUTEC, TTEF
                                for k in $SERVER3
                                do
                                        if [  $k = $APPNAME ]
                                        then
                                               APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                               HOMEPUBLICA=/opt/$APPAMBIENTE

                                               echo "`date +%c` -  Iniciando publicacao do server $HOST3 - $APPNAME - $AMBIENTE"
                                               echo "`date +%c` - Removendo deploy anterior da $APPNAME remota"
                                               "`$CMDUSER "/usr/bin/ssh $HOST3 -C rm -f $HOMEPUBLICA/$APPNAME*bin"`"

                                               echo "`date +%c` -  Copiando binario ${j} para a pasta de publicacao"
                                               `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $HOST3:$HOMEPUBLICA"`

                                               #Verificando PID da APP a ser publicada
                                               PID=`$CMDUSER "/usr/bin/ssh $HOST3 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                                                if [ "$PID" != "" ]
                                                then
                                                        echo "`date +%c` - Parando aplicacao $APPNAME"
                                                        `$CMDUSER "/usr/bin/ssh $HOST3 -C kill -9 $PID 2> /dev/null"`
                                                        `$CMDUSER "/usr/bin/ssh $HOST3 -C rm -f /var/run/$APP$INST-$APPAMBIENTE.pid"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME ja esta parada"
                                                fi

                                                echo "`date +%c` -  Publicando aplicacao"
                                                `$CMDUSER "/usr/bin/ssh $HOST3 -C $HOMEPUBLICA/$j $HOMEPUBLICA $HOMEPUBLICA/conf/$APPNAME-ATUAL.properties"`
                                                echo
                                                echo "`date +%c` -  Publicacao  $APPNAME instalada no ambiente $AMBIENTE"
						
						#Removendo os arquivos instalados
                                                echo
                                                echo "`date +%c` - Removendo deploy $APPNAME local"
                                                "`rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j`"

#                                                echo "`date +%c` - Removendo deploy $APPNAME remoto"
#                                                "`$CMDUSER "/usr/bin/ssh $HOST3 -C rm -f $HOMEPUBLICA/$j"`"
                                                echo

                                                echo "`date +%c` -  Iniciando $APPNAME"
                                                `$CMDUSER "/usr/bin/ssh $HOST3 -C $STARTSGV $APP $APPAMBIENTE start"`

                                                 #Verificando se aplicacao esta ativa apos deploy
                                                 sleep 5
                                                 NOVOPID=`$CMDUSER "/usr/bin/ssh $HOST3 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`
                                                  PIDRUN=`$CMDUSER "/usr/bin/ssh $HOST3 -C cat /var/run/$APP$INST-$APPAMBIENTE.pid"`

                                                if [ "$NOVOPID" = "" ] && [ "$PIDRUN" != "$NOVOPID" ]
                                                then
                                                        echo "`date +%c` - A aplicacao $APPNAME nao esta subindo ou existe um pid antigo interrompendo a aplicacao"
                                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j ERROR"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME subiu com sucesso"
                                                        echo "Teste com o nome da app - $SISTEMA-$AMBIENTE-$ENVIAAPP $j"
                                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j"`


                                                         echo "Expurgando LOGS"
                                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                                        echo "Enviando Email de Publicacao"
                                                        echo "-----------------------------FIM--------------------------"
                                                        echo
                                                        `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br"  -q $LOGS $ENVIAEMAIL`

                                                fi

                                                echo
                                                echo "-----------------------------FIM--------------------------"

                                         fi

                                done

                                #PUBLICADOR DO PIN, CREDITO, FISICO, ASSETUR, COMPLEMENTAR
                                for k in $SERVER4
                                do
                                        if [  $k = $APPNAME ]
                                        then
                                               APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                               HOMEPUBLICA=/opt/$APPAMBIENTE

                                               echo "`date +%c` -  Iniciando publicacao do server $HOST4 - $APPNAME - $AMBIENTE"
                                               echo "`date +%c` - Removendo deploy anterior da $APPNAME remota"
                                               "`$CMDUSER "/usr/bin/ssh $HOST4 -C rm -f $HOMEPUBLICA/$APPNAME*bin"`"

                                               echo "`date +%c` -  Copiando binario ${j} para a pasta de publicacao"
                                               `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $HOST4:$HOMEPUBLICA"`

                                               #Verificando PID da APP a ser publicada
                                               PID=`$CMDUSER "/usr/bin/ssh $HOST4 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                                                if [ "$PID" != "" ]
                                                then
                                                        echo "`date +%c` - Parando aplicacao $APPNAME"
                                                        `$CMDUSER "/usr/bin/ssh $HOST4 -C kill -9 $PID 2> /dev/null"`
                                                        `$CMDUSER "/usr/bin/ssh $HOST4 -C rm -f /var/run/$APP$INST-$APPAMBIENTE.pid"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME ja esta parada"
                                                fi

                                                echo "`date +%c` -  Publicando aplicacao"
                                                `$CMDUSER "/usr/bin/ssh $HOST4 -C $HOMEPUBLICA/$j $HOMEPUBLICA $HOMEPUBLICA/conf/$APPNAME-ATUAL.properties"`
                                                echo
                                                echo "`date +%c` -  Publicacao  $APPNAME instalada no ambiente $AMBIENTE"

                                                #Removendo os arquivos instalados
                                                echo
                                                echo "`date +%c` - Removendo deploy $APPNAME local"
                                                "`rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j`"

#                                                echo "`date +%c` - Removendo deploy $APPNAME remoto"
#                                                "`$CMDUSER "/usr/bin/ssh $HOST4 -C rm -f $HOMEPUBLICA/$j"`"
                                                echo
                                                echo "`date +%c` -  Iniciando $APPNAME"
                                                `$CMDUSER "/usr/bin/ssh $HOST4 -C $STARTSGV $APP $APPAMBIENTE start"`

                                                 #Verificando se aplicacao esta ativa apos deploy
                                                 sleep 5
                                                 NOVOPID=`$CMDUSER "/usr/bin/ssh $HOST4 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`
                                                  PIDRUN=`$CMDUSER "/usr/bin/ssh $HOST4 -C cat /var/run/$APP$INST-$APPAMBIENTE.pid"`

                                                if [ "$NOVOPID" = "" ] && [ "$PIDRUN" != "$NOVOPID" ]
                                                then
                                                        echo "`date +%c` - A aplicacao $APPNAME nao esta subindo ou existe um pid antigo interrompendo a aplicacao"
                                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j ERROR"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME subiu com sucesso"
                                                        echo "Teste com o nome da app - $SISTEMA-$AMBIENTE-$ENVIAAPP $j"
                                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j"`



                                                         echo "Expurgando LOGS"
                                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                                        echo "Enviando Email de Publicacao"
                                                        echo "-----------------------------FIM--------------------------"
                                                        echo
                                                        `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br"  -q $LOGS $ENVIAEMAIL`

                                                fi

                                                echo
                                                echo "-----------------------------FIM--------------------------"

                                         fi

                                done

                                #PUBLICADOR OPERACIONAL E ASK
                                for k in $SERVER5
                                do
                                        if [  $k = $APPNAME ]
                                        then

                                               APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                               HOMEPUBLICA=/opt/$APPAMBIENTE

                                               echo "`date +%c` -  Iniciando publicacao do server $HOST5 - $APPNAME - $AMBIENTE"
                                               echo "`date +%c` - Removendo deploy anterior da $APPNAME remota"
                                               "`$CMDUSER "/usr/bin/ssh $HOST5 -C rm -f $HOMEPUBLICA/$APPNAME*bin"`"

                                               echo "`date +%c` -  Copiando binario ${j} para a pasta de publicacao"
                                               `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $HOST5:$HOMEPUBLICA"`

                                               #Verificando PID da APP a ser publicada
                                               PID=`$CMDUSER "/usr/bin/ssh $HOST5 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                                                if [ "$PID" != "" ]
                                                then
                                                        echo "`date +%c` - Parando aplicacao $APPNAME"
                                                        `$CMDUSER "/usr/bin/ssh $HOST5 -C kill -9 $PID 2> /dev/null"`
                                                        `$CMDUSER "/usr/bin/ssh $HOST5 -C rm -f /var/run/$APP$INST-$APPAMBIENTE.pid"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME ja esta parada"
                                                fi

                                                echo "`date +%c` -  Publicando aplicacao"
                                                `$CMDUSER "/usr/bin/ssh $HOST5 -C $HOMEPUBLICA/$j $HOMEPUBLICA $HOMEPUBLICA/conf/$APPNAME-ATUAL.properties"`
                                                echo
                                                echo "`date +%c` -  Publicacao  $APPNAME instalada no ambiente $AMBIENTE"

                                                echo
                                                echo "`date +%c` - Removendo deploy $APPNAME local"
                                                "`rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j`"

#                                               echo "`date +%c` - Removendo deploy $APPNAME remoto"
#                                               "`$CMDUSER "/usr/bin/ssh $HOST5 -C rm -f $HOMEPUBLICA/$j"`"
                                                echo
                                                echo "`date +%c` -  Iniciando $APPNAME"
                                                `$CMDUSER "/usr/bin/ssh $HOST5 -C $STARTSGV $APP $APPAMBIENTE start"`
                                                 #Verificando se aplicacao esta ativa apos deploy
                                                 sleep 5
                                                 NOVOPID=`$CMDUSER "/usr/bin/ssh $HOST5 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`
                                                  PIDRUN=`$CMDUSER "/usr/bin/ssh $HOST5 -C cat /var/run/$APP$INST-$APPAMBIENTE.pid"`

                                                if [ "$NOVOPID" = "" ] && [ "$PIDRUN" != "$NOVOPID" ]
                                                then
                                                        echo "`date +%c` - A aplicacao $APPNAME nao esta subindo ou existe um pid antigo interrompendo a aplicacao"
                                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j ERROR"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME subiu com sucesso"
                                                        echo "Teste com o nome da app - $SISTEMA-$AMBIENTE-$ENVIAAPP $j"
                                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j"`


                                                         echo "Expurgando LOGS"
                                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                                        echo "Enviando Email de Publicacao"
                                                        echo "-----------------------------FIM--------------------------"
                                                        echo
                                                        `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br"  -q $LOGS $ENVIAEMAIL`

                                                fi

                                                echo
                                                echo "-----------------------------FIM--------------------------"
                                         fi

                                done

                                for k in $SERVER6
                                do
                                        if [  $k = $APPNAME ]
                                        then
                                               APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                               HOMEPUBLICA=/opt/$APPAMBIENTE

                                               echo "`date +%c` -  Iniciando publicacao do server $HOST6 - $APPNAME - $AMBIENTE"
                                               echo "`date +%c` - Removendo deploy anterior da $APPNAME remota"
                                               "`$CMDUSER "/usr/bin/ssh $HOST6 -C rm -f $HOMEPUBLICA/$APPNAME*bin"`"

                                               echo "`date +%c` -  Copiando binario ${j} para a pasta de publicacao"
                                               `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $HOST6:$HOMEPUBLICA"`

                                               #Verificando PID da APP a ser publicada
                                               PID=`$CMDUSER "/usr/bin/ssh $HOST6 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                                                if [ "$PID" != "" ]
                                                then
                                                        echo "`date +%c` - Parando aplicacao $APPNAME"
                                                        `$CMDUSER "/usr/bin/ssh $HOST6 -C kill -9 $PID 2> /dev/null"`
                                                        `$CMDUSER "/usr/bin/ssh $HOST6 -C rm -f /var/run/$APP$INST-$APPAMBIENTE.pid"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME ja esta parada"
                                                fi

                                                echo "`date +%c` -  Publicando aplicacao"
                                                `$CMDUSER "/usr/bin/ssh $HOST6 -C $HOMEPUBLICA/$j $HOMEPUBLICA $HOMEPUBLICA/conf/$APPNAME-ATUAL.properties"`
                                                echo
                                                echo "`date +%c` -  Publicacao  $APPNAME instalada no ambiente $AMBIENTE"

                                                echo
                                                echo "`date +%c` - Removendo deploy $APPNAME local"
                                                "`rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j`"

#                                                echo "`date +%c` - Removendo deploy $APPNAME remoto"
#                                                "`$CMDUSER "/usr/bin/ssh $HOST6 -C rm -f $HOMEPUBLICA/$j"`"
                                                echo

                                                echo "`date +%c` -  Iniciando $APPNAME"
                                                `$CMDUSER "/usr/bin/ssh $HOST6 -C $STARTSGV $APP $APPAMBIENTE start"`

                                                 #Verificando se aplicacao esta ativa apos deploy
                                                 sleep 5
                                                 NOVOPID=`$CMDUSER "/usr/bin/ssh $HOST6 -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`
                                                  PIDRUN=`$CMDUSER "/usr/bin/ssh $HOST6 -C cat /var/run/$APP$INST-$APPAMBIENTE.pid"`

                                                if [ "$NOVOPID" = "" ] && [ "$PIDRUN" != "$NOVOPID" ]
                                                then
                                                        echo "`date +%c` - A aplicacao $APPNAME nao esta subindo ou existe um pid antigo interrompendo a aplicacao"
                                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j ERROR"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME subiu com sucesso"
                                                        echo "Teste com o nome da app - $SISTEMA-$AMBIENTE-$ENVIAAPP $j"
                                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j"`


                                                         echo "Expurgando LOGS"
                                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                                        echo "Enviando Email de Publicacao"
                                                        echo "-----------------------------FIM--------------------------"
                                                        echo
                                                        `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br"  -q $LOGS $ENVIAEMAIL`

                                                fi

                                                echo
                                                echo "-----------------------------FIM--------------------------"

                                         fi

                                done

                                for k in $SERVERM
                                do
                                        if [  $k = $APPNAME ]
                                        then

                                              APPAMBIENTE=homologa
                                               HOMEPUBLICA=/opt/homologacao

                                               echo "`date +%c` -  Iniciando publicacao do server $HOSTM - $APPNAME - $AMBIENTE"
                                               echo "`date +%c` - Removendo deploy anterior da $APPNAME remota"
                                               "`$CMDUSER "/usr/bin/ssh $HOSTM -C rm -f $HOMEPUBLICA/$APPNAME*bin"`"

                                               echo "`date +%c` -  Copiando binario ${j} para a pasta de publicacao"
                                               `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $HOSTM:$HOMEPUBLICA"`

                                               #Verificando PID da APP a ser publicada
                                               PID=`$CMDUSER "/usr/bin/ssh $HOSTM -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`

                                                if [ "$PID" != "" ]
                                                then
                                                        echo "`date +%c` - Parando aplicacao $APPNAME"
                                                        `$CMDUSER "/usr/bin/ssh $HOSTM -C kill -9 $PID 2> /dev/null"`
                                                        `$CMDUSER "/usr/bin/ssh $HOSTM -C rm -f /var/run/$APP$INST-$APPAMBIENTE.pid"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME ja esta parada"
                                                fi

                                                echo "`date +%c` -  Publicando aplicacao"
                                                `$CMDUSER "/usr/bin/ssh $HOSTM -C $HOMEPUBLICA/$j $HOMEPUBLICA $HOMEPUBLICA/conf/$APPNAME-ATUAL.properties"`
                                                echo
                                                echo "`date +%c` -  Publicacao  $APPNAME instalada no ambiente $AMBIENTE"

                                                #Removendo os arquivos instalados
                                                echo
                                                echo "`date +%c` - Removendo deploy $APPNAME local"
                                                "`rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j`"

#                                                echo "`date +%c` - Removendo deploy $APPNAME remoto"
#                                                "`$CMDUSER "/usr/bin/ssh $HOSTM -C rm -f $HOMEPUBLICA/$j"`"
                                                echo


                                                echo "`date +%c` -  Iniciando $APPNAME"
                                                `$CMDUSER "/usr/bin/ssh $HOSTM -C $STARTSGV $APP homologacao start"`

                                                 #Verificando se aplicacao esta ativa apos deploy
                                                 sleep 5
                                                 NOVOPID=`$CMDUSER "/usr/bin/ssh $HOSTM -C ps ax | grep $APP$INST-$APPAMBIENTE | grep -v "grep" | sed s/^[\ ]*//g | egrep -o ^[0-9]*"`
                                                 PIDRUN=`$CMDUSER "/usr/bin/ssh $HOSTM -C cat /var/run/$APP$INST-$APPAMBIENTE.pid"`

                                                if [ "$NOVOPID" = "" ] && [ "$PIDRUN" != "$NOVOPID" ]
                                                then
                                                        echo "`date +%c` - A aplicacao $APPNAME nao esta subindo ou existe um pid antigo interrompendo a aplicacao"
                                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j ERROR"`
                                                else
                                                        echo "`date +%c` -  A App $APPNAME subiu com sucesso"
                                                        echo "Teste com o nome da app - $SISTEMA-$AMBIENTE-$ENVIAAPP $j"
                                                        `$CMDUSER "/usr/bin/php /var/www/html/retornopublicaHost.php $SISTEMA-$AMBIENTE-HOST $j"`


                                                         echo "Expurgando LOGS"
                                                        `/bin/cat $LOGS >> $EXPURGO_LOGS`

                                                        echo "Enviando Email de Publicacao"
                                                        echo "-----------------------------FIM--------------------------"
                                                        echo
                                                        `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br"  -q $LOGS $ENVIAEMAIL`

                                                fi

                                                echo
                                                echo "-----------------------------FIM--------------------------"

                                         fi

                                done

                        done

                        echo
                        echo "-----------------------------FIM--------------------------"

                        else
                                echo "Publicacao em execucao"
                	fi

                       `echo "" ` > "$PUBLICAHOME/PIDSITHOST.pid"
                        PIDSITUATINT=""

        done

else

	echo "`date +%c` - Nao existem deploys de HOST para atualizar"
fi

