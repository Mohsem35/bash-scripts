#!/bin/bash
day=$(date +%F)
kill_process_script_log_directory=/var/log/ib/data/kill_idle_process
file_name=kill_process
kill_process_script_log_FILE=${file_name}-${day}.log
log_file=${kill_process_script_log_directory}/${kill_process_script_log_FILE}
POSTGRES_USER=ibprod
POSTGRES_DB=ibprod
PSQL_CMD=/usr/bin/psql
export PGPASSWORD=ibprod
echo "1. Start kill process At : `date +%F-%H:%M:%S.%N`" >> ${log_file}
${PSQL_CMD} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "select kill_idle_process()" >> ${log_file} 2>&1
echo "2. Kill process Ended At : `date +%F-%H:%M:%S.%N`" >> ${log_file}

