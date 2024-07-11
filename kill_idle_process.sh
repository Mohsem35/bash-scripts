#!/bin/bash

# Configuration
current_day=$(date +%F)
log_directory="/var/log/ib/data/kill_idle_process"
file_prefix="kill_process"
log_filename="${file_prefix}-${current_day}.log"
log_file="${log_directory}/${log_filename}"
postgres_user="ibprod"
postgres_db="ibprod"
psql_cmd="/usr/bin/psql"
export PGPASSWORD="ibprod"

# Ensure log directory exists
mkdir -p "${log_directory}"

# Start logging
echo "1. Start kill process At : $(date +%F-%H:%M:%S.%N)" >> "${log_file}"

# Execute PostgreSQL command
if ${psql_cmd} -U ${postgres_user} -d ${postgres_db} -c "select kill_idle_process()" >> "${log_file}" 2>&1; then
    echo "2. Kill process Ended At : $(date +%F-%H:%M:%S.%N)" >> "${log_file}"
else
    echo "Error: Failed to execute kill_idle_process function." >> "${log_file}"
fi

# Cleanup
unset PGPASSWORD

# Use trap to ensure cleanup happens even if the script exits prematurely
trap 'unset PGPASSWORD' EXIT
