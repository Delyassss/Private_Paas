#!/bin/bash

app_name="$1"
ref_name="$2"
branch="${ref_name#refs/heads/}"  #(#refs/heads/ here means "remove this prefix from the front of the string if present" — a Bash string-manipulation technique,

SCRIPT_DIR="$(cd $(dirname "$0") && pwd)"

REPO_PATH="${SCRIPT_DIR}/../repos/${app_name}.git"
APP_PATH="${SCRIPT_DIR}/../apps/${app_name}"
PAAS_PATH="${SCRIPT_DIR}/../"


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
            echo "Using Dockerfile !"
            echo "PORT=5000" >> "${APP_PATH}/.env"
            docker build -t ${app_name,,} ${APP_PATH}
            docker rm -f ${app_name}_container 2> /dev/null 
            docker run -d --restart unless-stopped --name ${app_name}_container  --network paas_net -e PORT=5000 ${app_name,,} #,, for lowecase
             cat << EOF | docker exec -i mypaas_nginx tee "/etc/nginx/conf.d/${app_name}.conf" > /dev/null # the second > to ignore the tee default stdout
server {
        listen 8081;
        listen [::]:8081;
        listen 80;
        listen [::]:80;
        server_name  ${app_name,,}.localhost:8081;

     location / {
        proxy_pass http://${app_name,,}:5000;
    }
}
EOF
            echo  -e "${app_name}_container\n" >> "${PAAS_PATH}/containers/name.log" # here i just save all the container names in file  and -e for /n
        fi
    else
    echo "PORT=5000" >> "${APP_PATH}/.env"
    PORT=5000 docker compose build -f "${YML_FILE}" 
    PORT=5000 docker compose  -f "${YML_FILE}"  up -d  && docker update --restart unless-stopped $(docker compose -f ${YML_FILE} ps -aq) #here
    # -q for just the container id 
    for container_id in $(docker compose -f ${YML_FILE} ps -qa); 
        do
            docker network connect paas_net "${container_id}" 2> /dev/null 
            service_name=$(docker inspect --format='{{.Name}}' ${container_id} | sed 's^\/^^')
            # the second > to ignore the tee default stdout AND the terminating EOF must be at colum 0
            cat << EOF | docker exec -i mypaas_nginx tee "/etc/nginx/conf.d/${service_name}.conf" > /dev/null 
server {
    listen 8081;
    listen [::]:8081;
    listen 80;
    listen [::]:80;
    server_name  ${service_name}.localhost ;
    
    location /  {
        proxy_pass http://${service_name}:5000;
    }
}
EOF
    echo  -e  "${container_id}\n" >> "${PAAS_PATH}/containers/name.log"
    done
            docker exec mypaas_nginx nginx -s reload
    fi








