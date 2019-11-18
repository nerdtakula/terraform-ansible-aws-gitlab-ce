#!/usr/bin/env bash

set -o pipefail

# Environment Variables
GITLAB_DATA_DIRECTORY="/mnt/gitlab-data/data"
GITLAB_BACKUP_DIRECTORY="${GITLAB_DATA_DIRECTORY}/backups"
LOCAL_BACKUP_DIRECTORY="/mnt/gitlab-data/to_upload"
CONTAINER_NAME="gitlab-ce"

# AWS S3 bucket
S3_REGION="us-west-1"
S3_BUCKET_NAME="viz-test-gitlabce-backups"
S3_BUCKET_PATH="/"
S3_ACL="x-amz-acl:private"
S3_KEY=""
S3_SECRET=""

# Lock file
LOCK_CHECK_INTERVAL=300
LOCK_FILE="${GITLAB_BACKUP_DIRECTORY}/.gitlab-backup-lock"
LOCK_TIMEOUT=43200

function putS3 {
    local FILE_PATH=$1
    local FILE_NAME=$2
    local DATE_NOW=$(date +"%a, %d %b %Y %T %z")
    local CONTENT_TYPE='application/x-compressed-tar'
    local REQ_STRING="PUT\n\n${CONTENT_TYPE}\n${DATE_NOW}\n${S3_ACL}\n/${S3_BUCKET_NAME}${S3_BUCKET_PATH}${FILE_NAME}"
    local SIGNATURE=$(echo -en "${REQ_STRING}" | openssl sha1 -hmac "${S3_SECRET}" -binary | base64)

    curl -L -X PUT -T "$FILE_PATH/$FILE_NAME" \
        -H "Host: ${S3_BUCKET_NAME}.s3.amazonaws.com" \
        -H "Date: ${DATE_NOW}" \
        -H "Content-Type: ${CONTENT_TYPE}" \
        -H "${S3_ACL}" \
        -H "Authorization: AWS ${S3_KEY}:${SIGNATURE}" \
        "https://${S3_BUCKET_NAME}.s3-${S3_REGION}.amazonaws.com${S3_BUCKET_PATH}${FILE_NAME}"

    local EXIT_CODE_1=$?
    echo "(?) Curl returned exit code: ${EXIT_CODE_1}"

    if [ ${EXIT_CODE_1} -ne 0 ]; then
        echo "(!) Couldn't upload to S3 Bucket. Manual intervention is advised."
    else
        echo "(✓) Gitlab successfully uploaded to S3 Bucket."
        # Remove backup from local disk
        rm -f $GITLAB_BACKUP_DIRECTORY/*_gitlab_backup.tar

        local EXIT_CODE_2=$?

        if [ ${EXIT_CODE_2} -ne 0 ]; then
            echo "(!) Couldn't cleanup local backup. Manual intervention is advised."
        else
            echo "(✓) Gitlab successfully copied off to backup server."
        fi
    fi
}

function backup {
    # Store the current timestamp (in seconds) in the lock file for future reference...
    echo "$(date +%s)" > "${LOCK_FILE}"

    local TIMESTAMP;

    # The timestamp of the backup (we chose ISO-8601 for clarity).
    TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    echo "==> Attempting to backup the gitlab."
    # docker exec $CONTAINER_NAME gitlab-rake gitlab:backup:create
    docker exec -t $CONTAINER_NAME gitlab-backup create

    local EXIT_CODE_1=$?

    if [ ${EXIT_CODE_1} -ne 0 ]; then
        echo "(!) Couldn't backup gitlab. Manual intervention is advised."
    else
        echo "(✓) Gitlab successfully backed-up."
    fi

    echo "==> Attempting to upload backup to S3 bucket."
    for file in "${GITLAB_BACKUP_DIRECTORY}"/*; do
        putS3 "${GITLAB_BACKUP_DIRECTORY}" "${file##*/}"
    done

    # Remove the lock file...
    rm -f "${LOCK_FILE}"
}

function maybe_start_backup {
    # Check for the presence of a lock file with size greater than zero. If it
    # exists it means that a backup process is already in place, and we should
    # not start a new one.
    echo "==> Checking if a backup is currently in progress."
    if [[ -s "${LOCK_FILE}" ]]; then
        echo "(!) A lock file is present."
        echo "(!) Maybe another backup process is already in place."
        echo "(!) The timeout for the backup process is $((LOCK_TIMEOUT / 3600))h."
        return 1;
    fi

    echo "==> Starting the backup procedure @ $(date)."

    backup & wait

    echo "==> Finished the backup procedure @ $(date)."
}

if [[ ! -d "${GITLAB_BACKUP_DIRECTORY}" ]];
then
    echo "Backup directory not present. Is the volume mounted?"
    exit 1
fi

if [[ ! -d "${GITLAB_DATA_DIRECTORY}" ]];
then
    echo "Data directory not present. Is the volume mounted?"
    exit 1
fi

maybe_start_backup
