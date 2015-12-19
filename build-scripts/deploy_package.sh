#!/bin/bash
set -e

function get_server_list() {
  SERVERS="${PACKAGE_BUILD_DIR}/server_${PACKAGE}.txt"
  if [ ! -f "$SERVERS" ]; then
    log "server.txt not present for the package."
    exit 0
  fi
  
  if [ -s "$SERVERS" ]; then
    AUTODEPLOY=$(cat "${SERVERS}" | grep -i "${TARGET}": | cut -d : -f2 | tr -d '[:space:]' | tr  "[:lower:]" "[:upper:]")
  fi
  
  if [ "$AUTODEPLOY" == 'OFF' ]; then
    log "Autodeploy is Off. Not pushing to servers"
    exit 0
  else
    if [ "$AUTODEPLOY" == 'ON' ]; then
      SERVER_LIST=$(cat "${SERVERS}" | grep -i "${TARGET}": | cut -d : -f2 | tr ',' ' ' )
    else
      SERVER_LIST=$(cat "${SERVERS}" | grep -i "${TARGET}": | cut -d : -f2 | tr ',' ' ' )
    fi
  fi
}

function deploy_deb_package() {
  if [ -z "${SERVER_LIST}" ]; then
    log "No deployment servers configured for environment $TARGET"
    exit 0
  else
    APT_CMD="sudo apt-get -qq"

    log "Server list is: ${SERVER_LIST}"
    for SERVER in "${SERVER_LIST[@]}"; do
      log "ssh ${SSH_OPTS_DEPLOY} -t -t ${SSH_USER}@${SERVER} \"export DEBIAN_FRONTEND=noninteractive; ${APT_CMD} update && ${APT_CMD} install $PACKAGE=$PACKAGE_VERSION\""
      log "Server is ${SERVER}"
      ssh ${SSH_OPTS_DEPLOY} -t -t "${SSH_USER}@${SERVER}" "export DEBIAN_FRONTEND=noninteractive; ${APT_CMD} update && ${APT_CMD} install ${PACKAGE}=${PACKAGE_VERSION}"

      
      ssh_status=$?
      if test $ssh_status -eq 0; then
        log "------"
        log "PASSED: Successfully installed package $PACKAGE on server $SERVER: Version: $PACKAGE_VERSION"
        log "------"
      else
        log "------"
        log "FAILED: WARNING! Failed to install $PACKAGE on server $SERVER: Version: $PACKAGE_VERSION"
        log "------"
      fi
      sleep "${WAIT_TIME_BETWEEN_DEPLOYS_ON_HOSTS}"
    done
  fi
}

function deploy_package() {
   get_server_list
   deploy_deb_package
} 
