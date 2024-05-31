#!/bin/bash

#####################################################
#                                                   #
# Only run this script ONCE, to create the DevOps   #
# infrastructure and production environment.        #
#                                                   #
#####################################################

# Log in to Docker Hub or your Docker registry
docker login -u hamzaedam01@gmail.com -p Cin#11149398

# Create network
docker network create -d overlay --attachable ops_overlay_network

# Build and run containers for Jenkins, Gogs, Registry, Prometheus and Grafana
docker-compose -f ../ops/docker-compose.ops.yml up -d

# Build images for production frontend, backend and database
docker-compose -f ../env-dev/docker-compose.staging.yml build
# docker pull mongo

# Push images to registry
docker image tag supspace-client edamh158/supspace-client:latest
docker image tag supspace-api edamh158/supspace-api:latest
# docker image tag mongo:4.4.17-focal edamh158/supspace-mongo:latest
docker image tag nginx:alpine edamh158/supspace-nginx:latest
docker push edamh158/supspace-api:latest
docker push edamh158/supspace-client:latest
# docker push edamh158/supspace-mongo:latest
docker push edamh158/supspace-nginx:latest

# Clean up local images
docker rmi edamh158/supspace-client
docker rmi edamh158/supspace-api
# docker rmi edamh158/supspace-mongo
docker rmi edamh158/supspace-nginx:latest
docker rmi supspace-client
docker rmi supspace-api
docker rmi mongo
docker rmi nginx:alpine

# Load production environment variables on this host, for stack startup
# export $(grep -v '^#' ./.env_prod | xargs)

# Start production
docker stack deploy --compose-file ../env-dev/docker-compose.prod.yml prod

# Add prod_client service to the ops_network, for smoke tests
docker service update --network-add ops_overlay_network prod_supspace-client
docker service update --network-add ops_overlay_network prod_supspace-api
docker service update --network-add ops_overlay_network prod_mongodb
docker service update --network-add ops_overlay_network prod_nginx

# remove production environment variables from host
# unset SRV_PORT
# unset MONGO_URI
# unset MONGO_PORT
# unset MONGO_INITDB_ROOT_USERNAME
# unset MONGO_INITDB_ROOT_PASSWORD
# unset NODE_ENV
# unset GIT_COMMIT

# Clean intermediate images - be carefull if you have other images that cannot be removed
echo "The next command may take some time (if you confirm)."
docker image prune