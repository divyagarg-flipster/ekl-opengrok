#!/usr/bin/env bash

# Run the following in a timed loop

prepare_repositories() {
   # Read repo.txt file to get all repos and their github url
   # In loop for each repo

   REPOS="${OPENGROK_PATH}/repo_${PACKAGE}.txt"
   if [ ! -f "$REPOS" ]; then
    log "repo.txt not present for the package."
    exit 0
   fi

   if [ ! -d "${REPOSITORY_PATH}" ]; then
    mkdir -p ${REPOSITORY_PATH}
   fi

   cd ${REPOSITORY_PATH}

   while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "Text read from file: $line"

    repo_name=$line | grep -o ":.*$" | cut -f2- -d':'
    git_repo_url= $line | grep -o "^.*:" | cut -d':' -f1
    echo $repo_name
    echo $git_repo_url
    if [ ! -d "${REPOSITORY_PATH}/repo_name" ]; then
        git clone $git_repo_url
    fi
    cd repo_name || exit 0
    git pull origin master
    cd ..
   done < "$REPOS"

}

index_repositories() {
    cd ${OPENGROK_PATH}
    OPENGROK_INSTANCE_BASE=opengrok-0.12.1 opengrok-0.12.1/bin/OpenGrok index ${REPOSITORY_PATH}
}

function log() {
   echo "[INFO]: $(date)": "$1" | tee -a "${LOGFILE}"
}

while true; do
    log "Preparing repositories"
    prepare_repositories
    log "Indexing repositories"
    #index_repositories
    sleep 300
done


