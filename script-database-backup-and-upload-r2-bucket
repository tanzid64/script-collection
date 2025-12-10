#!/bin/bash

# This script will take database backup and will upload into claudeflare r2 bucket -> will also delete all 7 days older backups from local machine.

# MySQL Credentials
USER="your_db_user_name"
PASSWORD="your_db_password"
DATABASE="your_db_name"

# R2 Bucket Info
BUCKET="r2_bucket_name"
ACCOUNT_ID="r2_account_id"
ENDPOINT="https://${ACCOUNT_ID}.r2.cloudflarestorage.com"
R2_BACKUP_DIR="r2_folder_directory"

# Backup directory
BACKUP_DIR="local_server_backup_path"

# Create directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# File name (only name)
FILENAME="${DATABASE}_$(date +'%Y-%m-%d_%H').sql"

# Full local path
FULL_PATH="$BACKUP_DIR/$FILENAME"

# Run mysqldump
mysqldump -u "$USER" -p"$PASSWORD" "$DATABASE" > "$FULL_PATH"

# Upload backup to R2 (upload ONLY the filename)
# You have to install aws cli to perform this acton
aws s3 cp "$FULL_PATH" "s3://$BUCKET/$R2_BACKUP_DIR/$FILENAME" --endpoint-url "$ENDPOINT"

# Delete local files older than 7 days
find "$BACKUP_DIR" -type f -mtime +7 -name "*.sql" -delete
