#!/bin/bash

S3CMD="/usr/local/bin/s3cmd --access_key={{rgw_backup.access_key}} --secret_key={{rgw_backup.secret_key}}  --host-bucket={{rgw_backup.host_bucket}} --host={{rgw_backup.host_base}} "
BACKUP_DIR_BASE="/backup"
BACKUP_DIR="${BACKUP_DIR_BASE}/{{ansible_hostname}}"
DAYS_TO_KEEP=7

/bin/mkdir -p "${BACKUP_DIR}"
/usr/sbin/slapcat -n 1 -l ${BACKUP_DIR}/ldap.data.ldif-`date "+%Y%m%d"`
/usr/bin/find "${BACKUP_DIR}" -mtime +${DAYS_TO_KEEP} -exec /bin/rm {} \;

$S3CMD sync --delete-removed "${BACKUP_DIR}/" "s3://{{rgw_backup.bucket_name}}/{{ansible_hostname}}/"
