#!/bin/bash
set -e

function compile_application() {
  cd "${WORKSPACE}"
  rm -rf "${PACKAGE_TARGET_PATH}"
  $ANT
}

function build_debian_package() {
  cd "${PACKAGE_BUILD_DIR}"

  log "Removing the previous files..."
  rm -rf "${PACKAGE_ROOT_PATH}"
  rm -rf "${PACKAGE_DEB_PATH}"

  mkdir -p "${PACKAGE_ROOT_PATH}"

  mkdir -p "${PACKAGE_ROOT_NAME}/DEBIAN"

  mkdir -p "${PACKAGE_ROOT_NAME}/etc/${PACKAGE}"
  mkdir -p "${PACKAGE_ROOT_NAME}/etc/init.d"
  mkdir -p "${PACKAGE_ROOT_NAME}/usr/share/${PACKAGE}/public"
  mkdir -p "${PACKAGE_ROOT_NAME}/usr/share/${PACKAGE}/resources"
  mkdir -p "${PACKAGE_ROOT_NAME}/var/lib/${PACKAGE}"

  cp package.control  "${PACKAGE_ROOT_NAME}/DEBIAN/control"
  cp package.postinst "${PACKAGE_ROOT_NAME}/DEBIAN/postinst"
  cp package.postrm   "${PACKAGE_ROOT_NAME}/DEBIAN/postrm"
  cp package.preinst  "${PACKAGE_ROOT_NAME}/DEBIAN/preinst"
  cp package.prerm    "${PACKAGE_ROOT_NAME}/DEBIAN/prerm"
  cp package-service  "${PACKAGE_ROOT_NAME}/etc/init.d/${PACKAGE}"
  cp ${PACKAGE_WAR_PATH} "${PACKAGE_ROOT_NAME}/var/lib/tomcat8/webapps/"

  sed -i -- "s/_VERSION_/${PACKAGE_VERSION}/g" "${PACKAGE_ROOT_NAME}/DEBIAN/control"
  sed -i -- "s/_GIT_COMMIT_/${GIT_SHA}/g"      "${PACKAGE_ROOT_NAME}/DEBIAN/control"


  # END your build script
  dpkg-deb -b "${PACKAGE_ROOT_NAME}"

  mv "${PACKAGE_ROOT_NAME}.deb" "${PACKAGE_DEB_PATH}"
  log "Successfully created debian package ${PACKAGE_DEB_PATH}"
}

function build_package() {
  compile_application
  build_debian_package
}
