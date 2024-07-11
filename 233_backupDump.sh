#!/usr/bin/env bash

export DB_NAME='ibprod'
export DB_USER='ibprod'
export PGPASSWORD='ibprod'
ZIP_CMD=gzip

LOG_FILE=/ibprod/logs/daily_"$(date +%Y-%m-%d)".log
DUMP_DIR=/ibprod/database
DUMP_FILE=${DUMP_DIR}/ibprodCBS_"$(date +%F-%H:%M:%S)".sql

/usr/bin/touch ${LOG_FILE}

printf "\033[1;96m%s\n" "--------------------- Backup Script --------------------" | tee -a "${LOG_FILE}"

printf "\033[1;96m1. %-30s : $(date +%Y-%m-%d)__$(date +%H.%M.%S)\n" "Start Time" | tee -a "${LOG_FILE}"

/bin/rm -rf ${DUMP_DIR}/*

pg_dump -U ${DB_USER} -d ${DB_NAME} > ibprod_$(date +%Y-%m-%d) --file=${DUMP_FILE}

printf "\033[1;96m2. %-30s : ibprod\n" "Backup database" | tee -a "${LOG_FILE}"

${ZIP_CMD} ${DUMP_FILE}

DUMP_FILE_ZIP=${DUMP_FILE}.gz

#send dump copy to backup server
#scp -r ${DUMP_FILE_ZIP} ubuntu@192.168.190.80:/home/ubuntu/ibProd36DumpFiles

scp -r ${DUMP_FILE_ZIP} ubuntu@192.168.190.231:/home/ubuntu/ibCbsDumpFiles

printf "\033[1;96m3. %-30s : ibprod\n" "Transfer database" | tee -a "${LOG_FILE}"

printf "\033[1;96m4. %-30s : $(date +%Y-%m-%d)__$(date +%H.%M.%S)\n" "End Time" | tee -a "${LOG_FILE}"

unset DB_NAME
unset DB_USER
unset PGPASSWORD
~                  


#!/usr/bin/env bash

export DB_NAME='ibprod'
export DB_USER='ibprod'
export PGPASSWORD='ibprod'

LOG_DIR=/ibprod/logs
DUMP_DIR=/ibprod/database
LOG_FILE="${LOG_DIR}/daily_$(date +%Y-%m-%d).log"
DUMP_FILE="${DUMP_DIR}/ibprodCBS_$(date +%F-%H%M%S).dump"

# Ensure the log and dump directories exist
mkdir -p "${LOG_DIR}" "${DUMP_DIR}"

/usr/bin/touch "${LOG_FILE}"

printf "\033[1;96m%s\n" "--------------------- Backup Script --------------------" | tee -a "${LOG_FILE}"
printf "\033[1;96m1. %-30s : $(date +%Y-%m-%d)__$(date +%H.%M.%S)\n" "Start Time" | tee -a "${LOG_FILE}"

# Clear the dump directory
/bin/rm -rf "${DUMP_DIR:?}"/*

# Database dump with custom format
pg_dump -U "${DB_USER}" -d "${DB_NAME}" -Fc --file="${DUMP_FILE}"

if [ $? -eq 0 ]; then
    printf "\033[1;96m2. %-30s : Success\n" "Backup database" | tee -a "${LOG_FILE}"
else
    printf "\033[1;91m2. %-30s : Failed\n" "Backup database" | tee -a "${LOG_FILE}"
    exit 1
fi

# Send dump copy to backup server
scp -r "${DUMP_FILE}" ubuntu@192.168.190.231:/home/ubuntu/ibCbsDumpFiles

if [ $? -eq 0 ]; then
    printf "\033[1;96m3. %-30s : Success\n" "Transfer database" | tee -a "${LOG_FILE}"
else
    printf "\033[1;91m3. %-30s : Failed\n" "Transfer database" | tee -a "${LOG_FILE}"
    exit 1
fi

printf "\033[1;96m4. %-30s : $(date +%Y-%m-%d)__$(date +%H.%M.%S)\n" "End Time" | tee -a "${LOG_FILE}"

unset DB_NAME DB_USER PGPASSWORD