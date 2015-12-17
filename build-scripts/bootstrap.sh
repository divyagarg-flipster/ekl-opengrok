#!/bin/bash
set -e

function define_variables() {
  export PACKAGE=ekl-opengrok
  export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home
  export ANT="/usr/local/bin/ant"
  export SSH_USER=fk-build-user
  export VERSION_PREFIX=1
  export GIT_SHA=$(git log | head -1 | cut -f2 -d" " | cut -c1-6)
  export PACKAGE_VERSION=$(date +%s)
  export GIT_REPO="git@github.com:divyagarg-flipster/ekl-opengrok.git"
  export PACKAGE_BUILD_DIR="${WORKSPACE}/build-scripts"
  export PACKAGE_ROOT_NAME="package_root"
  export PACKAGE_ROOT_PATH="${PACKAGE_BUILD_DIR}/${PACKAGE_ROOT_NAME}"
  export PACKAGE_TARGET_PATH="${WORKSPACE}/dist"
  export PACKAGE_DEB_PREFIX="${PACKAGE}_${PACKAGE_VERSION}"
  export PACKAGE_DEB_NAME="${PACKAGE_DEB_PREFIX}_all.deb"
  export PACKAGE_DEB_PATH="${PACKAGE_TARGET_PATH}/${PACKAGE_DEB_NAME}"
  export PACKAGE_WAR_NAME="source.jar"
  export PACKAGE_WAR_PATH="${PACKAGE_TARGET_PATH}/${PACKAGE_WAR_NAME}"


  # TODO: Add ssh keys in other environments
  if [ "$DEPLOYMENT_ENV" == 'LOCAL' ]; then
    export APT_SERVERS="flo-apt-repo.nm.flipkart.com"
  elif [ "$DEPLOYMENT_ENV" == 'ch' ]; then
    # APT_SERVERS="stage-build1.nm.flipkart.com stage-build1.ch.flipkart.com sb-ch-build1.ch.flipkart.com wzy-build1.ops.ch.flipkart.com"
    export SSH_KEY=/var/lib/jenkins/.ssh/fk-build-user.key.stage-ch.squeeze
    export APT_SERVERS="stage-build1.ch.flipkart.com"
  elif [ "$DEPLOYMENT_ENV" == 'PRODUCTION' ]; then
    export APT_SERVERS="prod-build1.nm.flipkart.com wzy-build1.nm.flipkart.com"
  elif [ "$DEPLOYMENT_ENV" == 'MPIE' ]; then
    export APT_SERVERS="mp-build1.ch.flipkart.com"
  elif [ "$DEPLOYMENT_ENV" == 'MPIE2' ]; then
    export APT_SERVERS="mp2-build1.ch.flipkart.com"
  elif [ "$DEPLOYMENT_ENV" == 'SB-CH' ]; then
    export APT_SERVERS="sb-ch-build1.ch.flipkart.com"
  else
    log "Unknown environment specified!"
    exit 255;
  fi
  
  export SSH_OPTS="-i $SSH_KEY -o CheckHostIP=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o BatchMode=yes"
}

function log() {
   echo "[INFO]: $(date)": "$1"
}

function source_scripts() {
  source "${PACKAGE_BUILD_DIR}/build_package.sh"
  source "${PACKAGE_BUILD_DIR}/upload_package.sh"
  source "${PACKAGE_BUILD_DIR}/deploy_package.sh"
}

function validate_environment() {
  if [ -z "${WORKSPACE}" ]; then
    log "WORKSPACE env variable is not set."
    exit 255
  fi
  
  if [ -z "${DEPLOYMENT_ENV}" ]; then
    log "DEPLOYMENT_ENV env variable is not set."
    exit 255
  fi

  if [ -z "${JAVA_HOME}" ]; then
    log "JAVA_HOME env variable is not set. For jdk-8 it could be something like /usr/lib/jvm/java-8-oracle"
    exit 255
  fi

  if [ ! -x "${ANT}" ]; then
    log "${ANT} not found"
    exit 255
  fi
  
  log "Java version: $(java -version)"
  log "Ant version: $($ANT -version)"
}

function main() {
  log "Starting package deployment"
  log "Workspace: $WORKSPACE"
  cd "${WORKSPACE}"
  
  log "Setting environment"
  define_variables "$@"
  log "Finished setting environment"

  log "Validating environment"
  validate_environment
  log "Finished validating environment"

  log "Sourcing scripts"
  source_scripts
  log "Finished sourcing scripts"

  log "Building package"
  build_package
  log "Finished building package"

  log "Uploading package"
  #upload_package
  log "Finished uploading package"

  log "Deploying package"
  #deploy_package
  log "Finished deploying package"
}

main "$@"
