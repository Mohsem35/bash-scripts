#------------------------------------from github copilot---------------------------------------------

#!/bin/bash

# Production server details
PROD_SERVER="192.168.190.231"
REMOTE_USER="ubuntu"
DUMP_DIR="/home/ubuntu/ibProdDumpFiles/"
LOCAL_DIR="/home/ubuntu/ibprod_dump_files/"
SFTP_BATCH_FILE="sftp_batch.txt"


# Check if the current user is 'ubuntu'
if [ "$(whoami)" != "ubuntu" ]; then
    echo "This script can only be run by the 'ubuntu' user."
    exit 1
fi


# Start the OpenVPN service at the beginning of the script
echo "Starting OpenVPN service..."
sudo systemctl start openvpn@doerOvpn.service
if [ $? -eq 0 ]; then
    echo "OpenVPN service started successfully."
else
    echo "Failed to start OpenVPN service."
    exit 1
fi


# Setup a trap to cleanup the batch file in case of script exit
trap 'rm -f "$SFTP_BATCH_FILE"' EXIT

# Identify the latest dump file on the production server
LATEST_DUMP=$(ssh -o ConnectTimeout=10 "$REMOTE_USER@$PROD_SERVER" "ls -t $DUMP_DIR | head -n1")

# Check if a file name was received
if [ -z "$LATEST_DUMP" ]; then
    echo "No dump files found in $DUMP_DIR"
    exit 1
fi

# Create a batch file for sftp commands
echo "get ${DUMP_DIR}${LATEST_DUMP} ${LOCAL_DIR}${LATEST_DUMP}" > "$SFTP_BATCH_FILE"

# Securely transfer the latest dump file to local machine using sftp in batch mode
if sftp -b "$SFTP_BATCH_FILE" -o ConnectTimeout=10 "$REMOTE_USER@$PROD_SERVER"; then
    echo "Latest database dump ($LATEST_DUMP) transferred successfully."
    # Now, send this file to the second server
    RESTORE_SERVER="ubuntu@172.16.7.50"
    RESTORE_SERVER_DIR="/home/ubuntu/internetbanking/ibprod/database" # Adjust this path as needed
    
    if -r scp "$LOCAL_DIR$LATEST_DUMP" "$RESTORE_SERVER:$RESTORE_SERVER_DIR"; then
        echo "Latest database dump ($LATEST_DUMP) transferred successfully to $RESTORE_SERVER."
    else
        echo "Failed to transfer the database dump to $RESTORE_SERVER."
        exit 1
    fi
else
    echo "Failed to transfer the database dump."
    exit 1
fi

# Stop the OpenVPN service at the end of the script execution
echo "Stopping OpenVPN service..."
sudo systemctl stop openvpn@doerOvpn.service
if [ $? -eq 0 ]; then
    echo "OpenVPN service stopped successfully."
else
    echo "Failed to stop OpenVPN service."
    exit 1
fi

