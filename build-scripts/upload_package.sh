#!/bin/bash
set -e

function cleanup() {
  # Delete the md5 file and .deb file
  rm -f "${TEMP_DIR}/${PACKAGE_DEB_NAME}"
  rm -f "${TEMP_DIR}/${PACKAGE_DEB_NAME}.md5"
}

function upload_deb_package() {
  cd "${WORKSPACE}"
  log "Package deploy env: ${DEPLOYMENT_ENV}"

  TEMP_DIR=/tmp/apt-repo
  if [ ! -d "${TEMP_DIR}" ]; then
    mkdir -p "${TEMP_DIR}"
  fi

  SSH_USER=fk-build-user

  # Copy the file to temp dir and generate md5
  cp "${PACKAGE_DEB_PATH}" "${TEMP_DIR}/"
  cd "${TEMP_DIR}"

  # Create an md5 file in current dir
  openssl md5 "$PACKAGE_DEB_NAME" | cut -f 2 -d " " > "${PACKAGE_DEB_NAME}.md5"

  log "Upload starting for $PACKAGE_DEB_NAME"
  # Upload the file and md5

  PACKAGE_TARGET_APT_PATH="/var/data/ftp-all/apt/${PACKAGE_DEB_NAME}"

  for APT_SERVER in $APT_SERVERS; do
    log "Uploading $PACKAGE_DEB_NAME to $APT_SERVER"
    log "scp ${SSH_OPTS} ${PACKAGE_DEB_NAME} ${SSH_USER}@${APT_SERVER}:${PACKAGE_TARGET_APT_PATH}"
    scp ${SSH_OPTS} "${PACKAGE_DEB_NAME}" "${SSH_USER}@${APT_SERVER}:${PACKAGE_TARGET_APT_PATH}"
    status=$?
    log "status is $status"
    if test $status -eq 0; then
      log "------"
      log "PASSED: Successfully pushed package $PACKAGE_DEB_NAME on server $APT_SERVER"
      log "------"
    else
      log "------"
      log "FAILED: WARNING! Failed to push $PACKAGE_DEB_NAME on server $APT_SERVER"
      log "------"
    fi
    
    log "ssh ${SSH_OPTS} -t -t ${SSH_USER}@${APT_SERVER} \"sudo -u fk-ops-build flock /var/lock/fk-update-apt.lock -c \"/usr/sbin/fk-update-apt ${PACKAGE_TARGET_APT_PATH}\"\""
    ssh ${SSH_OPTS} -t -t "${SSH_USER}@${APT_SERVER}" "sudo -u fk-ops-build flock /var/lock/fk-update-apt.lock -c \"/usr/sbin/fk-update-apt ${PACKAGE_TARGET_APT_PATH}\""
    status=$?
    log "status is $status"
    if test $status -eq 0; then
      log "------"
      log "PASSED: Successfully updated package $PACKAGE_DEB_NAME on server $APT_SERVER"
      log "------"
    else
      log "------"
      log "FAILED: WARNING! Failed to update $PACKAGE_DEB_NAME on server $APT_SERVER"
      log "------"
    fi
    
    log "ssh ${SSH_OPTS} ${SSH_USER}@${APT_SERVER} \"/bin/rm -f ${PACKAGE_TARGET_APT_PATH}\""
    ssh ${SSH_OPTS} "${SSH_USER}@${APT_SERVER}" "/bin/rm -f ${PACKAGE_TARGET_APT_PATH}"

    status=$?
    log "status is $status"
    if test $status -eq 0; then
      log "------"
      log "PASSED: Successfully removed temporary package $PACKAGE_DEB_NAME on server $APT_SERVER"
      log "------"
    else
      log "------"
      log "FAILED: WARNING! Failed to remove temporary package $PACKAGE_DEB_NAME on server $APT_SERVER"
      log "------"
    fi
  done
}

function upload_package() {
  upload_deb_package
  cleanup
}
