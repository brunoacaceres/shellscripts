#!/bin/bash

LOGS=/opt/publica/log/"Publicador-`date +%Y%m%d`.log"
exec >> $LOGS 2>&1

PID=`/bin/ls -l /opt/publica |grep PID | /bin/awk -F " " '{print $5}' | grep -v 0 | tail -n1`

echo "$PID"

#if [ "$PID" = ""  ]
#then
	echo
	echo "-----------------------------------------------"
	echo "Executando Deploy Web INT PRD SGV"
	echo "-----------------------------------------------"
	#/opt/publica/deploywebsgv.sh
#/opt/publica/deploywebsgv-bkp.sh # 2>&1 | tee /opt/publica/log/RelatorioPublicaWEB.log >> /opt/publica/log/"Publicacao-SITUATPRD-`date +%Y%m%d`.log"
 	/opt/publica/deployintprdsgv.sh
	echo "-----------------------------------------------"
	echo
	echo
	echo "-----------------------------------------------"
	echo "Executando Deploy Web SIT UAT SGV"
	echo "-----------------------------------------------"
	/opt/publica/deploywebsgv.sh #2>&1 | tee /opt/publica/log/RelatorioPublicaGF3.log >> /opt/publica/log/Publicacao-GF3-`date +%Y%m%d`.log
	echo "-----------------------------------------------"
	echo
	echo "-----------------------------------------------"
	echo "Executando Deploy HOST SIT SGV"
	echo "-----------------------------------------------"
	/opt/publica/deployhostsitnew.sh #2>&1 | tee /opt/publica/log/RelatorioPublicaHost.log >> /opt/publica/log/Publicacao-HOST-`date +%Y%m%d`.log
	echo "-----------------------------------------------"
	echo
        echo "-----------------------------------------------"
        echo "Executando Deploy HOST PRD SGV"
        echo "-----------------------------------------------"
	/opt/publica/deployhostprd.sh  >> /opt/publica/log/Publicacao-HOST-PRD-`date +%Y%m%d`.log
        echo "-----------------------------------------------"
        echo
	echo "-----------------------------------------------"
	echo "Executando Deploy Conciliadores HML SGV"
	echo "-----------------------------------------------"
	/opt/publica/deployconchml.sh #2>&1 | tee /opt/publica/log/RelatorioPublicaConciliadores.log >> /opt/publica/log/Publicacao-CONC-`date +%Y%m%d`.log
	echo "-----------------------------------------------"
	echo
	echo "-----------------------------------------------"
	echo "Executando Deploy Conciliadores INT SGV"
	echo "-----------------------------------------------"
	#/opt/publica/deployconcint.sh 
	echo "-----------------------------------------------"
	echo
	echo "-----------------------------------------------"
	echo "Executando Deploy SGR HML"
	echo "-----------------------------------------------"
	/opt/publica/deploywebsgr.sh 2>&1 | tee /opt/publica/log/RelatorioPublicaSGR.log >> /opt/publica/log/Publicacao-SGR-`date +%Y%m%d`.log
	echo "-----------------------------------------------"
        echo
        echo "-----------------------------------------------"
        echo "Executando Deploy SIG HML"
        echo "-----------------------------------------------"
        /opt/publica/deploysighml.sh 
        echo "-----------------------------------------------"
	echo
        echo "-----------------------------------------------"
        echo "Executando Deploy SERVICES HML"
        echo "-----------------------------------------------"
	/opt/publica/deployserviceshml.sh
        echo "-----------------------------------------------"
#else
#	echo "`date +%c` - Script de Publicacao em Andamento"
	
#fi
