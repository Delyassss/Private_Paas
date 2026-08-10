#!/bin/bash

app_name="$1"
SCRIPT_DIR="$(cd $(dirname "$0") && pwd)"

REPO_PATH="${SCRIPT_DIR}/../repos/${app_name}.git"

if [[ "${app_name}" =~ ^[[:space:]]*$ ]];
then 
   echo "Error: No argument provided."
   exit 1
fi

if [ ! -d "${REPO_PATH}" ];
then 
    echo "Repo already exist"
    exit 1
fi





