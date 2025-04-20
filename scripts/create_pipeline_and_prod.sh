#!/bin/bash

#####################################################
#                                                   #
# Only run this script ONCE, to create the DevOps   #
# infrastructure and production environment.        #
#                                                   #
#####################################################

# Check if .env.prod exists
if [ ! -f ./.env.prod ]; then
  echo "Error: .env.prod file not found!"
  echo "Please create this file based on .env.prod.example"
  echo "DO NOT commit this file to git!"
  exit 1
fi

# Load production environment variables on this host, for stack startup and docker login
export $(grep -v '^#' ./.env.prod | xargs)

# Validate required environment variables
if [ -z "$DOCKER_CREDS_USR" ] || [ -z "$DOCKER_CREDS_PSW" ]; then
  echo "Error: Docker credentials are missing in .env.prod file"
  exit 1
fi

# Log in to Docker Hub or your Docker registry
echo "$DOCKER_CREDS_PSW" | docker login -u "$DOCKER_CREDS_USR" --password-stdin

# Create network
docker network create -d overlay --attachable ops_overlay_network

# Create volumes for Jenkins, Prometheus and Grafana
sudo mkdir -p ../ops/var/prometheus/prometheus_data
sudo mkdir -p ../ops/etc/prometheus
sudo chmod -R 777 ../ops/var/prometheus/prometheus_data
sudo chmod -R 777 ../ops/etc/prometheus

sudo mkdir -p ../ops/var/grafana/grafana_data
sudo mkdir -p ../ops/etc/grafana/provisioning
sudo chmod -R 777 ../ops/var/grafana/grafana_data
sudo chmod -R 777 ../ops/etc/grafana/provisioning

# Build and run containers for Jenkins Prometheus and Grafana
docker-compose -f ../ops/docker-compose.ops.yml up -d

# Build images for production frontend, backend and database
docker-compose -f ../env-dev/docker-compose.staging.yml build
# docker pull mongo

# Push images to registry
docker image tag enetspace-client $DOCKER_CREDS_USR/enetspace-client:latest
docker image tag enetspace-api $DOCKER_CREDS_USR/enetspace-api:latest
docker image tag env-dev-nginx $DOCKER_CREDS_USR/enetspace-nginx:latest
docker push $DOCKER_CREDS_USR/enetspace-api:latest
docker push $DOCKER_CREDS_USR/enetspace-client:latest
docker push $DOCKER_CREDS_USR/enetspace-nginx:latest

# Clean up local images
docker rmi $DOCKER_CREDS_USR/enetspace-client
docker rmi $DOCKER_CREDS_USR/enetspace-api
docker rmi $DOCKER_CREDS_USR/enetspace-nginx:latest
docker rmi enetspace-client
docker rmi enetspace-api
docker rmi mongo
docker rmi env-dev-nginx

# Start production
docker stack deploy --compose-file ../env-dev/docker-compose.prod.yml prod

# Add prod_client service to the ops_network, for smoke tests
docker service update --network-add ops_overlay_network prod_enetspace-client
docker service update --network-add ops_overlay_network prod_enetspace-api
docker service update --network-add ops_overlay_network prod_mongodb
docker service update --network-add ops_overlay_network prod_nginx

# Remove production environment variables from host
unset SRV_PORT
unset MONGO_URI
unset MONGO_PORT
unset MONGO_INITDB_ROOT_USERNAME
unset MONGO_INITDB_ROOT_PASSWORD
unset NODE_ENV
unset GIT_COMMIT
unset DOCKER_CREDS_USR
unset DOCKER_CREDS_PSW

# Clean intermediate images - be careful if you have other images that cannot be removed
echo "The next command may take some time (if you confirm)."
docker image prune
