#!/bin/bash

app_name="$1"

SCRIPT_DIR="$(cd $"(dirname "$0")" && pwd)"

APP_PATH="${SCRIPT_DIR}/../apps/${app_name}"
REPO_PATH="${SCRIPT_DIR}/../repos/${app_name}.git"
YML_FILE=$(find "${APP_PATH}" -maxdepth 1 -type f -name "docker-compose.yml")


read -p "Are you sure you want to delete your app permanetly ? (yes/no)" answer
    if [ "$answer" == "no" ];
    then
        echo "exiting ..."
        exit 1
    elif [ "$answer" == "yes" ];
        then
        echo "deleting ..."
        docker rm -f ${app_name,,}_container 2> /dev/null 
        for container_id in $(docker compose -f "${YML_FILE}" ps -aq) ;
            do
                docker rm -f ${container_id} 2> /dev/null 
            done
        rm -rf "${APP_PATH}"
        rm -rf "${REPO_PATH}"
        else
        echo "Invalid input, exiting for safety ..."
        exit 1

    fi
    
