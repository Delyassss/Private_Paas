#!/bin/bash

if ! docker network ls | grep -q paas_net; #-q quit no ouput
then
    docker network create paas_net
    echo "network "paas_net" created"
fi

if ! docker ps -a --format "{{.Names}} | {{.State}}" | grep "mypass_nginx | running";
then 
    docker rm -f mypass_nginx 2> /dev/null 
    docker run -d --name mypaas_nginx -p "8081:80" --network paas_net nginx
fi