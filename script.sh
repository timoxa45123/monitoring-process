#!/bin/bash
#set -x
#source /root/.bashrc

API_SERVER_URL=http://192.168.0.124/monitoring/test/api
PROCESS_NAME=test.sh
LOG_FILE=/var/log/monitoring.log
PID_FILE=/var/log/ngind.pid

#Функции
function datenow  { date +"%d/%m/%y %T"; }

#Лог функции
function LOGSTART { echo "$(datenow) [OK] Start monitoring process $PROCESS_NAME. Current PID: $OLD_PROC_PID" >> $LOG_FILE; }
function LOGWARN  { echo "$(datenow) [WARNING] process $PROCESS_NAME restarted! Current PID: $PROC_PID" >> $LOG_FILE; }
function LOGAPI   { echo "$(datenow) [ERROR] API server not access! Head status: $API_STATUS" >> $LOG_FILE; }
function LOGAPIOK { echo "$(datenow) [OK] API server get access! Head status: $API_STATUS" >> $LOG_FILE; }


###Проверяет PID с лог файла, если не находит проверяет с помощью pgrep и логирует начало работы.
OLD_PROC_PID=$(tac $LOG_FILE | grep -m1 'Current PID\:' | grep -oE '[0-9]+$');
if [ -z $OLD_PROC_PID ]; then 
	OLD_PROC_PID=$(pgrep -o $PROCESS_NAME); if [ -z $OLD_PROC_PID ]; then exit 0; fi
	LOGSTART
fi

###Также и с API сервером
API_STATUS=$(tac $LOG_FILE | grep -m1 'Head status\:' | grep -oE '[0-9]+$')

if [ -z $API_STATUS ] || [ $API_STATUS -eq 200 ]; then API_ERROR=0; else API_ERROR=1; fi



#Функция проверки API сервера
function check_api {

	API_STATUS=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 5 --max-time 10 $API_SERVER_URL)
	if [ $API_STATUS -eq 200 ] && [ $API_ERROR -eq 1 ]; then LOGAPIOK;

	elif [ $API_STATUS -ne 200 ]; then
		LOGAPI
#		API_ERROR=1
	fi

}

#Функция проверки процесса по PID, сравнивается с PID, который был последним в лог файле
function check_proc {

	PROC_PID=$(pgrep -o $PROCESS_NAME);

	if [ -z $PROC_PID ]; then exit 0; fi

	if [ $PROC_PID -eq $OLD_PROC_PID ]; then
		check_api
		else
		LOGWARN
	fi
}

check_proc
exit 0

