#!/bin/bash
#set -x
#source /root/.bashrc

API_SERVER_URL=http://192.168.0.124/monitoring/test/api
PROCESS_NAME=test.sh
LOG_FILE=/var/log/monitoring.log

function datenow { date +"%d/%m/%y %T"; }
function LOGWARN { echo "$(datenow) [WARNING] process $PROCESS_NAME restarted! Current PID: $PROC_PID" >> $LOG_FILE; }
function LOGAPI  { echo "$(datenow) [ERROR] API server not access! head status: $API_STATUS" >> $LOG_FILE; }
OLD_PROC_PID=$(pgrep $PROCESS_NAME);
API_ERROR=0
echo "$(datenow) [WARNING] Start monitoring process $PROCESS_NAME. Current PID: $OLD_PROC_PID" >> $LOG_FILE;





function check_api {
	
	API_STATUS=$(curl -o /dev/null -s -w "%{http_code}" $API_SERVER_URL)
	if [ $API_STATUS -ne 200 ]; then 
		LOGAPI
		API_ERROR=1

	elif [ $API_STATUS -eq 200 ] && [ $API_ERROR -eq 1 ]; then echo "$(datenow) [OK] API server GET access! Head status: $API_STATUS" >> $LOG_FILE; API_ERROR=0;
	fi

}
function check_proc {

	PROC_PID=$(pgrep $PROCESS_NAME);

	if [ -z $PROC_PID ]; then return 0; fi

#	if ! [ -s $LOG_FILE ]; then LOGWARN; fi

	if [ $PROC_PID -eq $OLD_PROC_PID ]; then
		check_api
		else
		LOGWARN
		OLD_PROC_PID=$PROC_PID
	fi
}

while true
do

	check_proc
	sleep 60

done

