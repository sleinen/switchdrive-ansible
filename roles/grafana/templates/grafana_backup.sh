#!/bin/bash

S3CMD="/usr/bin/s3cmd --access_key={{rgw_backup.access_key}} --secret_key={{rgw_backup.secret_key}}  --host-bucket={{rgw_backup.host_bucket}} --host={{rgw_backup.host_base}} "
BACKUP_DIR_BASE="{{grafana_data_dir}}/backup"
BACKUP_DIR="${BACKUP_DIR_BASE}/{{ansible_hostname}}"
DAYS_TO_KEEP=7

/usr/bin/docker stop grafana
/bin/mkdir -p "${BACKUP_DIR}"
/bin/cp "{{grafana_data_dir}}/data/grafana.db" "${BACKUP_DIR}"/grafana.db-`date "+%Y%m%d"`
/usr/bin/find "${BACKUP_DIR}" -mtime +${DAYS_TO_KEEP} -exec /bin/rm {} \;

$S3CMD sync --delete-removed "${BACKUP_DIR}/" "s3://{{rgw_backup.bucket_name}}/{{ansible_hostname}}/"

/usr/bin/docker start grafana
