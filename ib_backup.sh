#======================================New Script====================================== 

#!/usr/bin/env bash

# Configuration
export DB_NAME='ibprod'
export DB_USER='ibprod'
export PGPASSWORD='ibprod'
ZIP_CMD='gzip'
LOG_DIR="/var/lib/db_backups/ibprod/logs"
DUMP_DIR="/var/lib/db_backups/ibprod" # Updated directory path
DATE=$(date +%Y-%m-%d-%H:%M:%S)
LOG_FILE="${LOG_DIR}/daily_${DATE}.log"
# DUMP_FILE="${DUMP_DIR}/ibprod_${DATE}.sql"
DUMP_FILE="${DUMP_DIR}/ibprod_${DATE}.dump"
DUMP_FILE_ZIP="${DUMP_FILE}.gz"

# Ensure the dump and log directories exist
mkdir -p "${DUMP_DIR}" "${LOG_DIR}"

# Start logging
/usr/bin/touch "${LOG_FILE}"
printf "\033[1;96m%s\n" "--------------------- Backup Script --------------------" | tee -a "${LOG_FILE}"
printf "\033[1;96m1. %-30s : ${DATE}\n" "Start Time" | tee -a "${LOG_FILE}"


# Database dump
# pg_dump -U "${DB_USER}" -d "${DB_NAME}" -f "${DUMP_FILE}"
pg_dump -U "${DB_USER}" -d "${DB_NAME}" -f "${DUMP_FILE}" -Fc

if [ $? -eq 0 ]; then
    printf "\033[1;96m2. %-30s : Success\n" "Backup database" | tee -a "${LOG_FILE}"
    
    # Since the dump is in custom format and already compressed, you might skip the gzip step
    # If you decide to keep the gzip step, remember the file is already compressed, making further compression optional
    # Compress the dump file
    gzip "${DUMP_FILE}"
    if [ $? -eq 0 ]; then
        printf "\033[1;96m2.1 %-30s : Success\n" "Compress database dump" | tee -a "${LOG_FILE}"
    else
        printf "\033[1;91m2.1 %-30s : Failed\n" "Compress database dump" | tee -a "${LOG_FILE}"
        exit 1
    fi
else
    printf "\033[1;91m2. %-30s : Failed\n" "Backup database" | tee -a "${LOG_FILE}"
    exit 1
fi


# Transfer dump file to backup server
scp -v "${DUMP_FILE}.gz" ubuntu@192.168.190.231:/home/ubuntu/ibProdDumpFiles
if [ $? -eq 0 ]; then
    printf "\033[1;96m3. %-30s : Success\n" "Transfer database" | tee -a "${LOG_FILE}"
else
    printf "\033[1;91m3. %-30s : Failed\n" "Transfer database" | tee -a "${LOG_FILE}"
    exit 1
fi


# Cleanup old backups, keep only the latest
cd "${DUMP_DIR}" || exit
if [ $(ls -1 | wc -l) -gt 1 ]; then
    ls -t | tail -n +2 | xargs rm --
fi


# Capture the current time as the end time
END_TIME=$(date '+%Y-%m-%d-%H:%M:%S')

# End logging with the updated end time
printf "\033[1;96m4. %-30s : ${END_TIME}\n" "End Time" | tee -a "${LOG_FILE}"


# Cleanup
unset DB_NAME DB_USER PGPASSWORD