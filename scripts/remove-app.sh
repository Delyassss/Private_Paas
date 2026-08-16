#!/bin/bash

app_name="$1"
z
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" # so dirname strips the no-directory suffixes  dirname a/v/c.txt  -> a/v

APP_PATH="${SCRIPT_DIR}/../apps/${app_name}"
REPO_PATH="${SCRIPT_DIR}/../repos/${app_name}.git"
YML_FILE=$(find "${APP_PATH}" -maxdepth 1 -type f -name "docker-compose.yml")

if [[ "${app_name}" =~ ^[[:space:]]*$ ]]; then
    echo "Error: No argument provided."
    exit 1
fi

if [ ! -d "${APP_PATH}" ];
then 
    echo "Error: app does not exist for ${app_name}"
    exit 1
fi

if [ ! -d "${REPO_PATH}" ];
then 
    echo "Error: repo does not exist for ${app_name}"
    exit 1
fi
read -p "Are you sure you want to delete your app permanetly ? 
(yes/no)  :  " answer
    if [ "$answer" == "no" ];
    then
        echo "exiting ..."
        exit 1
    elif [ "$answer" == "yes" ];
        then
        echo "deleting ..."
        if [[ "${YML_FILE}" =~ ^[[:space:]]*$ ]];
            then 
                echo "did not find docker-compose.yml ! Dockerfile will be used instead"
            else
                for container_id in $(docker compose -f "${YML_FILE}" ps -aq) ;
                do
                    docker rm -f ${container_id} 2> /dev/null 
                done
            fi
        docker rm -f ${app_name,,}_container 2> /dev/null 
        rm -rf "${APP_PATH}"
        rm -rf "${REPO_PATH}"
        else
            echo "Invalid input, exiting for safety ..."
            exit 1

    fi
    
