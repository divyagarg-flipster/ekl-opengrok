#!/usr/bin/env bash


prepare_repositories() {
   # Read repo.txt file to get all repos and their github url
   REPOS="${OPENGROK_PATH}/repo_${PACKAGE}.txt"
   if [ ! -f "$REPOS" ]; then
    log "repo.txt not present for the package."
    exit 0
   fi

   if [ ! -d "${REPOSITORY_PATH}" ]; then
    mkdir -p ${REPOSITORY_PATH}
   fi
   cd ${REPOSITORY_PATH}

   cat $REPOS|while read line; do
        echo "Text read from file: $line"
        git_repo_url=$(echo $line | grep -o ":.*$" | cut -f2- -d':')
        git_repo_name=$(echo $line | grep -o "^.*:" | cut -d':' -f1)
        echo "Repo Name: $git_repo_name"
        echo "Repo Url: $git_repo_url"

        if [ ! -d "${REPOSITORY_PATH}/${git_repo_name}" ]; then
            echo 'Cloning repo ${git_repo_name}'
            git clone ${git_repo_url} | tee -a "${LOGFILE}"
            log "Cloning completed for ${git_repo_name}"
        fi
        log "Entering repo ${git_repo_name}"
        cd ${git_repo_name} || exit 0
        echo "Pulling Repo : ${git_repo_name}"
        git pull origin master | tee -a "${LOGFILE}"
        log "Pull operation completed for ${git_repo_name}"
        cd ..
   done


}

index_repositories() {
    cd ${OPENGROK_PATH}
    OPENGROK_INSTANCE_BASE=opengrok-0.12.1 opengrok-0.12.1/bin/OpenGrok index ${REPOSITORY_PATH}
    cd ..
}

function log() {
   echo "[INFO]: $(date)": "$1" | tee -a "${LOGFILE}"
}

function main(){

    export PACKAGE="ekl-opengrok"
    export LOGFILE="/var/log/flipkart/supply-chain/${PACKAGE}/${PACKAGE}.log"
    export OPENGROK_PATH="/var/lib/${PACKAGE}"
    export REPOSITORY_PATH="${OPENGROK_PATH}/repositories/src_root"
    export USERNAME="fk-supply-chain"
    echo "$(date) ${SUDO_USER:-$USER}  $(whoami)" >> ${REPOSITORY_PATH}/grok_user.txt

    echo "In index_repositories file main function"

    log "Preparing repositories"
    prepare_repositories
     log "Indexing repositories"
    index_repositories

}

main