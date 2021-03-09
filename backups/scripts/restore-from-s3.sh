#!/bin/bash
set -eo pipefail

DATABASE_TARGET=$1
BACKUP_FILE_NAME=$2
BACKUP_DOWNLOADED_FILE_NAME=$BACKUP_FILE_NAME
BACKUP_FILE_DESTINATION=/backups/$BACKUP_DOWNLOADED_FILE_NAME

if [ ! -f "$AWS_SHARED_CREDENTIALS_FILE" ]; then
  echo "AWS-S3: No credentials configured for AWS S3 - skipping restore."
  exit 0
fi

if [ -z "$BACKUP_FILE_NAME" ]; then
  echo "AWS-S3: You have to pass backup file name as second parameter for this script."
  exit 1
fi

if [ -z "$AWS_S3_BUCKET_NAME" ]; then
  echo "AWS-S3: You have to pass AWS S3 bucket name in 'AWS_S3_BUCKET_NAME' variable."
  exit 1
fi

if [ -z "$AWS_S3_SSE_CUSTOMER_KEY" ]; then
  echo "AWS-S3: You have to pass SSE Customer Key for client side encryption as 'AWS_S3_SSE_CUSTOMER_KEY' variable."
  exit 1
fi

echo
echo "AWS-S3: Downloading backup s3://$AWS_S3_BUCKET_NAME/$BACKUP_FILE_NAME"
aws s3 cp --sse-c AES256 --sse-c-key "fileb://$AWS_S3_SSE_CUSTOMER_KEY" "s3://$AWS_S3_BUCKET_NAME/$BACKUP_FILE_NAME" "$BACKUP_FILE_DESTINATION"

/restore.sh "$DATABASE_TARGET" "$BACKUP_DOWNLOADED_FILE_NAME"

RESTORE_RESULT=$?

echo
if [ $RESTORE_RESULT -eq 0 ]; then
  echo "AWS-S3: Restoring backup - DONE s3://$AWS_S3_BUCKET_NAME/$BACKUP_FILE_NAME"
  exit 0
else
  echo "AWS-S3: Restoring backup - FAILED s3://$AWS_S3_BUCKET_NAME/$BACKUP_FILE_NAME"
  exit 1
fi