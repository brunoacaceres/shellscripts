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
SISTEMA="SGV"

ENVIAEMAIL="infra.java@redetendencia.com.br"

#-----------------------------WEB------------------------------------------------------------

PUBLICAHOME=/opt/publica
TODAY="`date +%Y%m%d`"

#-----------------------------HOST------------------------------------------------------------

#Servidores e seus aplicativos
SERVERS="sa-switch sa-pdvcel"
SERVER1="sa-am"
SERVER2="sa-online-v"
SERVER3="sa-am-tef sa-ttef sa-itautec sa-x25"
SERVER4="sa-pin sa-complementar sa-credito sa-fisico sa-assetur sa-blackhawk"
SERVER5="sa-oper sa-ask"
SERVER6="sa-sptrans sa-riocard sa-sfa sa-acessocard"
SERVER17="sa-mfs sa-f3m sa-pop"
SERVERM="sa-mux sa-servcel"

#Variaveis de publicacao e expurgo local e remoto
UPLOADPUBLICA=/opt/publica
TODAY="`date +%Y%m%d`"
INST=01
HOMEPUBLICA=/opt/$APPAMBIENTE
STARTSGV=/opt/publica/sgvhost.sh
#LOGS=/opt/publica/log/"Publicacao-HOSTPRD-`date +%Y%m%d`.log"
LOGS="/opt/publica/log/"RelatorioHostPrd.log""
echo " " > $LOGS
#Armazenando logs
#exec >> $LOGS 2>&1

#Busca de Ambiente que existem aplicacoes a serem publicadas
PUBLICAHOST="`/bin/find "$UPLOADPUBLICA" -name "sa-*" |  /bin/awk -F "/" '{print $4}' | /bin/egrep -o ^[A-Z]*| /usr/bin/uniq`"

PIDPUB=`ps ax | grep "/opt/publica/deployhostprd.sh" | grep -v grep | awk -F " " '{print $1}'`

PIDPRDHOST="`cat $PUBLICAHOME/PIDPRDHOST.pid 2> /dev/null `"

if [ "$PUBLICAHOST" != ""  ]
then
        for i in $PUBLICAHOST
        do
                AMBIENTE=${i}
                if [ "$AMBIENTE" = "PRD" ] && [ "$PIDPRDHOST" = "" ]
                then
			#echo " " > $LOGS
                        #exec >> $LOGS 2>&1
                        exec &>> >(tee "$LOGS")
                        APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                        APPSPUBLICA="`/bin/ls "$UPLOADPUBLICA/$AMBIENTE/sgv/host/" | grep sa- |   /bin/awk -F "-" '{print $0}' `"
                        HOMEPUBLICA=/opt/$APPAMBIENTE
			OLDDEPLOYS=$HOMEPUBLICA/old_deploys
                        echo $PIDPUB > $PUBLICAHOME/PIDPRDHOST.pid
                        PIDPRDHOST="`cat $PUBLICAHOME/PIDPRDHOST.pid`"
			echo "Projetos relacionados na publicacao"
			/bin/cat /opt/git/repo/host/MANIFEST
 			echo
			echo "APPSPUBLICA= $APPSPUBLICA"

                        #IPS DOS SERVIDORES DOS AMBIENTES PRD HOSTS
                        if [ "$AMBIENTE" = "PRD"  ]
                        then
                                HOSTS="172.16.58.1 172.16.58.2 172.16.58.3 172.16.58.4 172.16.58.5 172.16.58.6 172.16.58.7 172.16.58.8"
                                HOST1="172.16.52.1 172.16.52.11 172.16.52.21"
                                HOST2="172.16.52.9 172.16.52.10"
                                HOST3="172.16.52.3"
                                HOST4="172.16.52.4 172.16.52.14"
                                HOST5="172.16.52.5 172.16.52.15 172.16.52.25"
                                HOST6="172.16.52.6 172.16.52.16"
				HOST17="172.16.52.17"
                                HOSTM="172.16.51.1"

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
                                                for H in $HOSTS
                                                do
                                                        if [ ! -s $LOGS ] ; then
                                                                #echo "$LOGS is empty."
                                                                 exec &>> >(tee "$LOGS")
                                                        #else
                                                                #echo "$LOGS has data."
                                                        fi
                                                       APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                                       HOMEPUBLICA=/opt/$APPAMBIENTE
                                                       echo
                                                       echo "-----------INICIANDO COPIA APP $k------------"
                                                       echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                                                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                                       `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                                       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                                       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
                                                        #CHECKSUM DAS APPS LOCAL E REMOTA

                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#                                                               exit 1;
                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#                                                               echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#                                                              `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                                        fi

                                                       echo "-----------------FIM COPIA APP $k------------"
                                                       echo
                                                 done

                                                 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
                                                 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
                                                 #Limpando LOGS apos envio de email
                                                 `/bin/rm -f  $LOGS`
                                        fi
                                done
												 

                                #PUBLICADOR DO AM
                                for k in $SERVER1
                                do
                                         if [  $k = $APPNAME ]
                                         then
                                                for H in $HOST1
                                                do
                                                        if [ ! -s $LOGS ] ; then
                                                                #echo "$LOGS is empty."
                                                                 exec &>> >(tee "$LOGS")
                                                        #else
                                                                #echo "$LOGS has data."
                                                        fi
                                                       APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                                       HOMEPUBLICA=/opt/$APPAMBIENTE
                                                       echo
                                                       echo "-----------INICIANDO COPIA APP $k------------"
                                                       echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                                                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                                       `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                                       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                                       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
                                                        #CHECKSUM DAS APPS LOCAL E REMOTA

                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#                                                               exit 1;
                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#                                                               echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#                                                              `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                                        fi

                                                       echo "-----------------FIM COPIA APP $k------------"
                                                       echo
                                                 done

                                                 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
                                                 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
                                                 #Limpando LOGS apos envio de email
                                                 `/bin/rm -f  $LOGS`
                                        fi
                                done
												 
                                #PUBLICADOR DO ONLINE-V
                                for k in $SERVER2
                                do
                                         if [  $k = $APPNAME ]
                                         then
                                                for H in $HOST2
                                                do
                                                        if [ ! -s $LOGS ] ; then
                                                                #echo "$LOGS is empty."
                                                                 exec &>> >(tee "$LOGS")
                                                        #else
                                                                #echo "$LOGS has data."
                                                        fi
                                                       APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                                       HOMEPUBLICA=/opt/$APPAMBIENTE
                                                       echo
                                                       echo "-----------INICIANDO COPIA APP $k------------"
                                                       echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                                                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                                       `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                                       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                                       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
                                                        #CHECKSUM DAS APPS LOCAL E REMOTA

                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#                                                               exit 1;
                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#                                                               echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#                                                              `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                                        fi

                                                       echo "-----------------FIM COPIA APP $k------------"
                                                       echo
                                                 done

                                                 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
                                                 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
                                                 #Limpando LOGS apos envio de email
                                                 `/bin/rm -f  $LOGS`
                                        fi
                                done

                                #PUBLICADOR DO AM-TEF TTEF ITAUTEC 
                                for k in $SERVER3
                                do
                                         if [  $k = $APPNAME ]
                                         then
                                                for H in $HOST3
                                                do
                                                        if [ ! -s $LOGS ] ; then
                                                                #echo "$LOGS is empty."
                                                                 exec &>> >(tee "$LOGS")
                                                        #else
                                                                #echo "$LOGS has data."
                                                        fi
                                                       APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                                       HOMEPUBLICA=/opt/$APPAMBIENTE
                                                       echo
                                                       echo "-----------INICIANDO COPIA APP $k------------"
                                                       echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                                                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                                       `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                                       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                                       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
                                                        #CHECKSUM DAS APPS LOCAL E REMOTA

                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#                                                               exit 1;
                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#                                                               echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#                                                              `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                                        fi

                                                       echo "-----------------FIM COPIA APP $k------------"
                                                       echo
                                                 done

                                                 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
                                                 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
                                                 #Limpando LOGS apos envio de email
                                                 `/bin/rm -f  $LOGS`
                                        fi
                                done

                                #PUBLICADOR DO PIN COMPLEMENTAR CREDITO ASSETUR FISICO
                                for k in $SERVER4
                                do
                                         if [  $k = $APPNAME ]
                                         then
                                                for H in $HOST4
                                                do
                                                        if [ ! -s $LOGS ] ; then
                                                                #echo "$LOGS is empty."
                                                                 exec &>> >(tee "$LOGS")
                                                        #else
                                                                #echo "$LOGS has data."
                                                        fi
                                                       APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                                       HOMEPUBLICA=/opt/$APPAMBIENTE
                                                       echo
                                                       echo "-----------INICIANDO COPIA APP $k------------"
                                                       echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                                                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                                       `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                                       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                                       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
                                                        #CHECKSUM DAS APPS LOCAL E REMOTA

                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#                                                               exit 1;
                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#                                                               echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#                                                              `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                                        fi

                                                       echo "-----------------FIM COPIA APP $k------------"
                                                       echo
                                                 done

                                                 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
                                                 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
                                                 #Limpando LOGS apos envio de email
                                                 `/bin/rm -f  $LOGS`
                                        fi
                                done
												 												 												 
                                #PUBLICADOR DO OPER E ASK
				for k in $SERVER5
				do
               		                 if [  $k = $APPNAME ]
                                         then
		                                for H in $HOST5
                		                do
							if [ ! -s $LOGS ] ; then
							 	#echo "$LOGS is empty."
								 exec &>> >(tee "$LOGS")
							#else
								#echo "$LOGS has data."
							fi 
			        	               APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
				                       HOMEPUBLICA=/opt/$APPAMBIENTE
						       echo
						       echo "-----------INICIANDO COPIA APP $k------------"
                	                               echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                        	                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                	               `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                        	       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                               	       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
							#CHECKSUM DAS APPS LOCAL E REMOTA

        	                	                MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
		                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                		                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                		        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"
	
        		                                if [ $MD5DPLNOV != $MD5DPLPUB ]
                        		                then
                                        		        echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#		                                                exit 1;
        		                                else
                        		                        echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#		                                                echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#	        	                                       `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                        		                fi

 		   				       echo "-----------------FIM COPIA APP $k------------"
					      	       echo
						 done

						 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
						 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
						 #Limpando LOGS apos envio de email
						 `/bin/rm -f  $LOGS`
					fi
				done

                                #PUBLICADOR DO SPTRANS
                                for k in $SERVER6
                                do
                                         if [  $k = $APPNAME ]
                                         then
                                                for H in $HOST6
                                                do
                                                        if [ ! -s $LOGS ] ; then
                                                                #echo "$LOGS is empty."
                                                                 exec &>> >(tee "$LOGS")
                                                        #else
                                                                #echo "$LOGS has data."
                                                        fi
                                                       APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                                       HOMEPUBLICA=/opt/$APPAMBIENTE
                                                       echo
                                                       echo "-----------INICIANDO COPIA APP $k------------"
                                                       echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                                                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                                       `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                                       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                                       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
                                                        #CHECKSUM DAS APPS LOCAL E REMOTA

                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#                                                               exit 1;
                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#                                                               echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#                                                              `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                                        fi

                                                       echo "-----------------FIM COPIA APP $k------------"
                                                       echo
                                                 done

                                                 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
                                                 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
                                                 #Limpando LOGS apos envio de email
                                                 `/bin/rm -f  $LOGS`
                                        fi
                                done


                                #PUBLICADOR DO F3M MFS
                                for k in $SERVER17
                                do
                                         if [  $k = $APPNAME ]
                                         then
                                                for H in $HOST17
                                                do
                                                        if [ ! -s $LOGS ] ; then
                                                                #echo "$LOGS is empty."
                                                                 exec &>> >(tee "$LOGS")
                                                        #else
                                                                #echo "$LOGS has data."
                                                        fi
                                                       APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                                       HOMEPUBLICA=/opt/$APPAMBIENTE
                                                       echo
                                                       echo "-----------INICIANDO COPIA APP $k------------"
                                                       echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                                                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                                       `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                                       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                                       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
                                                        #CHECKSUM DAS APPS LOCAL E REMOTA

                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#                                                               exit 1;
                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#                                                               echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#                                                              `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                                        fi

                                                       echo "-----------------FIM COPIA APP $k------------"
                                                       echo
                                                 done

                                                 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
                                                 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
                                                 #Limpando LOGS apos envio de email
                                                 `/bin/rm -f  $LOGS`
                                        fi
                                done
												 

                                #PUBLICADOR DO MUX SERVCEL
                                for k in $SERVERM
                                do
                                         if [  $k = $APPNAME ]
                                         then
                                                for H in $HOSTM
                                                do
                                                        if [ ! -s $LOGS ] ; then
                                                                #echo "$LOGS is empty."
                                                                 exec &>> >(tee "$LOGS")
                                                        #else
                                                                #echo "$LOGS has data."
                                                        fi
                                                       APPAMBIENTE="`echo $AMBIENTE | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                                                       HOMEPUBLICA=/opt/$APPAMBIENTE
                                                       echo
                                                       echo "-----------INICIANDO COPIA APP $k------------"
                                                       echo "`date +%c` - Iniciando publicacao do server $H - $APPNAME - $AMBIENTE"
                                                       echo "`date +%c` - Copiando deploy anterior da $APPNAME remota"
                                                       `$CMDUSER "/usr/bin/ssh $H -C /bin/mv $HOMEPUBLICA/$APPNAME*bin $OLDDEPLOYS/"`

                                                       echo "`date +%c` - Copiando binario ${j} para a pasta de publicacao"
                                                       `$CMDUSER "/usr/bin/scp $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j $H:$HOMEPUBLICA"`
                                                        #CHECKSUM DAS APPS LOCAL E REMOTA

                                                        MD5DPLNOV=`$CMDUSER "/usr/bin/md5sum $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j" | /bin/awk -F " " '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy novo $MD5DPLNOV"
                                                        MD5DPLPUB=`$CMDUSER "/usr/bin/ssh $H -C /usr/bin/md5sum $HOMEPUBLICA/$j" | /bin/awk -F "/" '{print $1}'`
                                                        echo "`date +%c` - MD5 Deploy Publicado $MD5DPLPUB"

                                                        if [ $MD5DPLNOV != $MD5DPLPUB ]
                                                        then
                                                                echo "`date +%c` - A checagem MD5 esta incorreta, executar o deploy novamente"
#                                                               exit 1;
                                                        else
                                                                echo "`date +%c` -  A checagem MD5 e verdadeira! Publicacao efetuada com sucesso"
#                                                               echo "Enviando confirmacao de deploy  $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"
#                                                              `$CMDUSER "/usr/bin/php /var/www/html/retornopublica.php $SISTEMA-$AMBIENTE-$TIPO $APPWEBNOVA"`
                                                        fi

                                                       echo "-----------------FIM COPIA APP $k------------"
                                                       echo
                                                 done

                                                 #ENVIAR EMAIL POR HOST
                                                 `/bin/echo | /bin/mail -s "Publicacao $SISTEMA-$AMBIENTE-$ENVIAAPP $j" -r "infra.java@redetendencia.com.br" -q "$LOGS" $ENVIAEMAIL`
                                                 echo "`date +%c` - Removendo deploy da $j local apos a copia"
                                                 `$CMDUSER "/bin/rm -f $UPLOADPUBLICA/$AMBIENTE/sgv/host/$j"`
                                                 #Limpando LOGS apos envio de email
                                                 `/bin/rm -f  $LOGS`
                                        fi
                                done
												 												 


                        done

                        echo
                        echo "-----------------------------FIM--------------------------"

                        else
                                echo "Publicacao em execucao"
                	fi

                       `echo "" ` > "$PUBLICAHOME/PIDPRDHOST.pid"
                        PIDPRDHOST=""

        done

else

	echo "`date +%c` - Nao existem deploys de HOST para atualizar"
fi

