# PowerShell version of create_pipeline_and_prod.ps1
# Save this as create_pipeline_and_prod.ps1

################################################################
#                                                              #
# Only run this script ONCE, to create the DevOps              #
# infrastructure and production environment.                   #
#                                                              #
################################################################

# Load production environment variables
$envFile = Get-Content -Path ".\.env.prod" | Where-Object { $_ -notmatch "^#" -and $_ -match "=" }
foreach ($line in $envFile) {
    $name, $value = $line.split('=', 2)
    [Environment]::SetEnvironmentVariable($name, $value)
}

# Log in to Docker Hub
$password = [Environment]::GetEnvironmentVariable("DOCKER_CREDS_PSW")
$username = [Environment]::GetEnvironmentVariable("DOCKER_CREDS_USR")
echo $password | docker login -u $username --password-stdin

# Create network
docker network create -d overlay --attachable ops_overlay_network

# Create directories for Jenkins, Prometheus and Grafana
New-Item -Path "..\ops\var\prometheus\prometheus_data" -ItemType Directory -Force
New-Item -Path "..\ops\etc\prometheus" -ItemType Directory -Force
New-Item -Path "..\ops\var\grafana\grafana_data" -ItemType Directory -Force
New-Item -Path "..\ops\etc\grafana\provisioning" -ItemType Directory -Force

# Set permissions (less critical on Windows but added for completeness)
# We'll skip chmod commands as they don't apply to Windows

# Build and run containers for Jenkins, Prometheus and Grafana
docker-compose -f ..\ops\docker-compose.ops.yml up -d

# Build images for production frontend, backend and database
docker-compose -f ..\env-dev\docker-compose.staging.yml build

# Push images to registry - updated to use enetspace naming
docker image tag enetspace-client youssef37/enetspace-client:latest
docker image tag enetspace-api youssef37/enetspace-api:latest
docker image tag env-dev-nginx youssef37/enetspace-nginx:latest
docker push youssef37/enetspace-api:latest
docker push youssef37/enetspace-client:latest
docker push youssef37/enetspace-nginx:latest

# Clean up local images
docker rmi youssef37/enetspace-client
docker rmi youssef37/enetspace-api
docker rmi youssef37/enetspace-nginx:latest
docker rmi supspace-client
docker rmi supspace-api
docker rmi mongo
docker rmi env-dev-nginx

# Start production
docker stack deploy --compose-file ..\env-dev\docker-compose.prod.yml prod

# Add prod services to the ops_overlay_network, for smoke tests
docker service update --network-add ops_overlay_network prod_supspace-client
docker service update --network-add ops_overlay_network prod_supspace-api
docker service update --network-add ops_overlay_network prod_mongodb
docker service update --network-add ops_overlay_network prod_nginx

# Remove production environment variables from host
Remove-Item Env:SRV_PORT -ErrorAction SilentlyContinue
Remove-Item Env:MONGO_URI -ErrorAction SilentlyContinue
Remove-Item Env:MONGO_PORT -ErrorAction SilentlyContinue
Remove-Item Env:MONGO_INITDB_ROOT_USERNAME -ErrorAction SilentlyContinue
Remove-Item Env:MONGO_INITDB_ROOT_PASSWORD -ErrorAction SilentlyContinue
Remove-Item Env:NODE_ENV -ErrorAction SilentlyContinue
Remove-Item Env:GIT_COMMIT -ErrorAction SilentlyContinue
Remove-Item Env:DOCKER_CREDS_USR -ErrorAction SilentlyContinue
Remove-Item Env:DOCKER_CREDS_PSW -ErrorAction SilentlyContinue

# Clean intermediate images
Write-Host "The next command may take some time (if you confirm)."
docker image prune