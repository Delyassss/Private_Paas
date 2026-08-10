#!/bin/bash

app_name="$1"
ref_name="$2"
branch="${ref_name#refs/heads/}"  #(#refs/heads/ here means "remove this prefix from the front of the string if present" — a Bash string-manipulation technique,

SCRIPT_DIR="$(cd $(dirname "$0") && pwd)"

REPO_PATH="${SCRIPT_DIR}/../repos/${app_name}.git"
APP_PATH="${SCRIPT_DIR}/../apps/${app_name}"

if [[ "${app_name}" =~ ^[[:space:]]*$ ]];
then 
   echo "Error: No argument provided."
   exit 1
fi

if [ ! -d "${REPO_PATH}" ];
then 
    echo "Error: repo does not exist for ${app_name}"
    exit 1
fi

git --work-tree="${APP_PATH}" --git-dir="${REPO_PATH}" checkout -f ${branch}

YML_FILE=$(find "${APP_PATH}" -maxdepth 1 -type f -name "docker-compose.yml")

if [[ "${YML_FILE}" =~ ^[[:space:]]*$ ]];
    then 
        echo "did not find docker-compose.yml ! Dockerfile will be used instead"
        YML_FILE=$(find "${APP_PATH}" -maxdepth 1 -type f -name "Dockerfile")
        
        if [[ "${YML_FILE}" =~ ^[[:space:]]*$ ]];
            then 
                echo "did not find Dockerfile either !"
                exit 1
        else 
            docker build -t ${app_name,,} ${APP_PATH}
            docker rm -f ${app_name}_container 2> /dev/null 
            docker run -d --name ${app_name}_container  ${app_name,,}
        fi
    else
    docker-compose build -f "${YML_FILE}" 
    docker-compose up -d -f "${YML_FILE}"
    fi




