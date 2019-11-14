#!/usr/bin/env bash

set -o pipefail

# Environment Variables
GITLAB_DATA_DIRECTORY="/mnt/gitlab-data/data"
GITLAB_BACKUP_DIRECTORY="${GITLAB_DATA_DIRECTORY}/backups"
LOCAL_BACKUP_DIRECTORY="/mnt/gitlab-data"
CONTAINER_NAME="gitlab-ce"

# Lock file
LOCK_CHECK_INTERVAL=300
LOCK_FILE="${GITLAB_BACKUP_DIRECTORY}/.gitlab-backup-lock"
LOCK_TIMEOUT=43200

function backup {
    # Store the current timestamp (in seconds) in the lock file for future reference...
    echo "$(date +%s)" > "${LOCK_FILE}"

    local TIMESTAMP;

    # The timestamp of the backup (we chose ISO-8601 for clarity).
    TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    echo "==> Attempting to backup the gitlab."
    docker exec gitlab gitlab-rake gitlab:backup:create

    local EXIT_CODE_1=$?

    if [ ${EXIT_CODE_1} -ne 0 ]; then
        echo "(!) Couldn't backup gitlab. Manual intervention is advised."
    else
        echo "(✓) Gitlab successfully backed-up."
    fi

    echo "==> Attempting to copy backup to off local machine."
    cp $GITLAB_BACKUP_DIRECTORY/*_gitlab_backup.tar $LOCAL_BACKUP_DIRECTORY

    local EXIT_CODE_2=$?

    if [ ${EXIT_CODE_2} -ne 0 ]; then
        echo "(!) Couldn't copy backup off local machine. Manual intervention is advised."
    else
        echo "(✓) Gitlab successfully copied off to backup server."
        # Remove backup from local disk
        rm -f $GITLAB_BACKUP_DIRECTORY/*_gitlab_backup.tar

        local EXIT_CODE_3=$?

        if [ ${EXIT_CODE_3} -ne 0 ]; then
            echo "(!) Couldn't cleanup local backup. Manual intervention is advised."
        else
            echo "(✓) Gitlab successfully copied off to backup server."
        fi
    fi

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

    # Clean up old backups
    echo "==> Cleaning up old backups (older than 5 days."
    find $LOCAL_BACKUP_DIRECTORY/* -mtime +5 -exec rm {} \;

    local EXIT_CODE_4=$?

    if [ ${EXIT_CODE_4} -ne 0 ]; then
        echo "(!) Couldn't cleanup old backups. Manual intervention is advised."
    else
        echo "(✓) Successfully removed old backups."
    fi

    # Provide read access for tools that upload these backups off-site
    chmod +r $LOCAL_BACKUP_DIRECTORY/*.tar
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

if [[ -z "${LOCAL_BACKUP_DIRECTORY}" ]];
then
    echo "Target local backup location is not defined."
    exit 1
fi

maybe_start_backup
