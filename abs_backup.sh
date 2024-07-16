#!/bin/bash

# Configuration
DEPLOYMENT=prod
COMPRESS_COMMAND=gzip
POSTGRES_DB=agrani
# POSTGRES_SCHEMA=public
POSTGRES_USER=absprod
export PGPASSWORD=absprod
POSTGRES_DUMP_CMD=pg_dump
# PSQL_CMD=/bin/psql
PREVIOUS_DAY=$(date +%Y/%m/%d --date="1 day ago")
REMOTE_USER=fuad
REMOTE_MACHINE_IP=172.16.110.3
# PORT_NUMBER=22
ALLOWED_USER=abs
BACKUP_BASE=/var/log/csb/data/db_backup/${DEPLOYMENT}
CURRENT_DATE=$(date +%Y/%m/%d)
BACKUP_DIR=${BACKUP_BASE}/${CURRENT_DATE}
# POSTGRES_DUMP_FILE=${POSTGRES_DB}-${DEPLOYMENT}-$(date +%F-%H:%M:%S).dump
POSTGRES_DUMP_FILE=${POSTGRES_DB}-${DEPLOYMENT}-$(date +%F-%H:%M:%S).sql
BACKUP_LOG_FILE="${BACKUP_DIR}/backup.log"
BACKUP_ERR_FILE="${BACKUP_DIR}/backup.err"


# Functions
check_user() {
  log "Checking if the user is allowed to run this script."
  if [ "${USER}" != "${ALLOWED_USER}" ]; then
    echo "You must be logged in as ${ALLOWED_USER} to run this. Exiting ..."
    exit -1
  fi
  log "User verified successfully."
}


# Function to create a backup directory
create_backup_dir() {
  log "Creating backup directory."
  delete_old_backups  # Delete old backups before creating a new one
  
  if [ ! -e "${BACKUP_DIR}" ]; then
    mkdir -p "${BACKUP_DIR}"
    check_exit_status $? "Directory creation failed"
    exec 1>>"${BACKUP_DIR}/${BACKUP_LOG_FILE}"
    exec 2>>"${BACKUP_DIR}/${BACKUP_ERR_FILE}"
    log "Backup directory created: ${BACKUP_DIR}"
  else
    log "Directory exists: ${BACKUP_DIR}"
  fi
}

# Redirect STDOUT and STDERR
exec 1>>"$BACKUP_LOG_FILE"
exec 2>>"$BACKUP_ERR_FILE"

# Define a log function for easier logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$BACKUP_LOG_FILE"
}

# Start of the script
log "Starting ABS backup process."




# Function to delete old backups
delete_old_backups() {
  log "Deleting old backups."
  # Navigate to the base backup directory
  cd "${BACKUP_BASE}" || exit
  
  # Find and delete directories not matching today's date
  find . -mindepth 1 -maxdepth 3 -type d ! -path "./$(date +%Y)" ! -path "./$(date +%Y)/$(date +%m)" ! -path "./$(date +%Y)/$(date +%m)/$(date +%d)" -exec rm -rf {} +
  log "Old backups deleted successfully."
}



log_error() {
  # Use '+%Y-%m-%d %H:%M:%S %Z' for a format like '2023-04-01 12:00:00 UTC'
  echo "$(date '+%Y-%m-%d %H:%M:%S %Z') - ERROR - $1" >&2
}

check_exit_status() {
  if [ $1 -ne 0 ]; then
    log "$2"
    unset PGPASSWORD
    exit -1
  fi
}



# backup_database() {                                                  
#   ${POSTGRES_DUMP_CMD} -U ${POSTGRES_USER} -Fc -d ${POSTGRES_DB} -f ${BACKUP_DIR}/${POSTGRES_DUMP_FILE}
#   check_exit_status $? "Backup exception for Postgres database: ${POSTGRES_DB} into file ${BACKUP_DIR}/${POSTGRES_DUMP_FILE}"
#   log "Backup completed for ${POSTGRES_DB}: ${POSTGRES_DUMP_FILE}"
# }

backup_database() {                                                  
  # Removed -Fc to switch to plain SQL format and added -Fp explicitly
  ${POSTGRES_DUMP_CMD} -U ${POSTGRES_USER} -Fp -d ${POSTGRES_DB} -f ${BACKUP_DIR}/${POSTGRES_DUMP_FILE}
  check_exit_status $? "Backup exception for Postgres database: ${POSTGRES_DB} into file ${BACKUP_DIR}/${POSTGRES_DUMP_FILE}"
  log "Backup completed for ${POSTGRES_DB}: ${POSTGRES_DUMP_FILE}"
}



compress_backup() {
  ${COMPRESS_COMMAND} ${BACKUP_DIR}/${POSTGRES_DUMP_FILE}
  check_exit_status $? "Compression error for Postgres file: ${BACKUP_DIR}/${POSTGRES_DUMP_FILE}"
  log "Compression done for dump file: ${POSTGRES_DUMP_FILE}.gz"
}


transfer_files() {
  scp -v -r ${BACKUP_DIR}/${POSTGRES_DUMP_FILE}.gz ${REMOTE_USER}@${REMOTE_MACHINE_IP}:${BACKUP_DIR}
  check_exit_status $? "File transfer not complete: ${POSTGRES_DUMP_FILE}"
  log "File transfer process completed"
}


cleanup_old_backups() {
    log "Starting cleanup of old backups..."
    cd "${BACKUP_BASE}" || { log_error "Failed to navigate to backup base directory: ${BACKUP_BASE}"; exit 1; }
    ls -td */ | tail -n +2 | xargs rm -rf -- || log_error "Cleanup failed"
    log "Cleanup of old backups completed."
}


cleanup_variables() {
  unset USER
  unset ALLOWED_USER
  unset BACKUP_DIR
  unset BACKUP_LOG_FILE
  unset BACKUP_ERR_FILE
  unset POSTGRES_DUMP_CMD
  unset POSTGRES_USER
  unset POSTGRES_DB
  unset POSTGRES_DUMP_FILE
  unset COMPRESS_COMMAND
}


# Main
check_user
create_backup_dir
backup_database
compress_backup
transfer_files
cleanup_old_backups
cleanup_variables
log "Backup and cleanup process completed successfully."

exit 0


