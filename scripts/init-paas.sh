#!/bin/bash

if ! docker network ls | grep -q paas_net; #-q quit no ouput
then
    docker network create paas_net
    echo "network "paas_net" created"
fi

if ! docker ps -a --format "{{.Names}} | {{.State}}" | grep mypass_nginx;
then 
    docker run -d --name mypass_nginx -p "8081:80" --network pass_net nginx
fi