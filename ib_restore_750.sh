#!/bin/bash

# Configuration
DB_NAME='ibprod'
DB_USER='ibprod'
DB_PASSWORD='ibprod' # Note: This is not used in the script. Consider secure handling if needed.
DST_DIR="/home/ubuntu/internetbanking/${DB_NAME}/database/"
LOG_FILE="/home/ubuntu/internetbanking/${DB_NAME}/logs/daily_$(date +%Y-%m-%d_%H-%M-%S).log"

# Function to log messages with timestamp
log_message() {
  echo -e "\033[1;96m$1 : $(date +%Y-%m-%d_%H-%M-%S)\033[0m" | tee -a "${LOG_FILE}"
}

# Delete existing dump files in DST_DIR
log_message "1. Deleting existing previous dump files in ${DST_DIR}"
find "${DST_DIR}" -type f -name '*.sql' -print0 | sort -zr | tail -zn +2 | xargs -0 rm -f


# Logging message indicating cleanup is done
log_message "Deleted all previous dump files, kept only the latest."


# Unzip the SQL dump file
log_message "2. Unzipping SQL dump file"
gzip -d "${DST_DIR}/${DB_NAME}_*.sql.gz"
if [ $? -ne 0 ]; then
  log_message "Error unzipping file. Aborting."
  exit 1
fi

# Find the SQL file to restore (assuming only one should exist)
log_message "3. Finding SQL dump file"
SQL_FILE=$(find "${DST_DIR}" -type f -name "${DB_NAME}_*.sql" -print -quit)

if [[ -z "$SQL_FILE" ]]; then
  log_message "No SQL dump file found. Aborting."
  exit 1
fi

# Recreate the database
log_message "4. Creating database"
psql -v ON_ERROR_STOP=1 <<-EOSQL
  SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE 
    pid <> pg_backend_pid()
    AND datname = '${DB_NAME}';
  DROP DATABASE IF EXISTS ${DB_NAME};
  CREATE DATABASE ${DB_NAME} WITH OWNER=${DB_USER};
EOSQL

if [ $? -ne 0 ]; then
  log_message "Error creating database. Aborting."
  exit 1
fi

# Restore the database
log_message "5. Restoring database"
psql -U ${DB_USER} -d ${DB_NAME} < "$SQL_FILE"

if [ $? -ne 0 ]; then
  log_message "Error restoring database. Aborting."
  exit 1
fi

# Grant permissions using readuser.sql
log_message "6. Granting permissions to readuser"
psql -U ${DB_USER} -d ${DB_NAME} -f /home/ubuntu/readuser.sql

log_message "7. Database restored"
log_message "Process completed"

# Cleanup environment variables
unset PGDATABASE PGUSER PGPASSWORD