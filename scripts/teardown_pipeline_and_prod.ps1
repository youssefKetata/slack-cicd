################################################################
#                                                              #
# This script removes the DevOps infrastructure and            #
# production environment.                                      #
#                                                              #
################################################################

# Remove DevOps infrastructure
Write-Host "Stopping and removing DevOps containers..."
docker-compose -f ..\ops\docker-compose.ops.yml down

# Remove production
Write-Host "Removing production stack..."
docker stack rm prod

# Wait for stack to be fully removed
Write-Host "Waiting for production stack to be removed..."
Start-Sleep -Seconds 15

# Clean orphan images
Write-Host "The next command may take some time (if you confirm)."
$confirmation = Read-Host "Do you want to prune unused Docker images? (y/n)"
if ($confirmation -eq 'y') {
    docker image prune
}

# Clean orphan networks
$confirmation = Read-Host "Do you want to prune unused Docker networks? (y/n)"
if ($confirmation -eq 'y') {
    docker network prune
}

# Remove persistent data
Write-Host "WARNING: The next step will remove all Docker volumes associated with your CI/CD pipeline and applications."
Write-Host "This will delete all persistent data and you will need to reconfigure everything again."
$confirmation = Read-Host "Do you want to proceed with volume removal? (yes/no - type 'yes' to confirm)"

if ($confirmation -eq 'yes') {
    Write-Host "Removing Docker volumes..."
    docker volume rm ops_jenkins ops_prometheus_data ops_grafana_data prod_db_prod
    Write-Host "Volumes removed."
} else {
    Write-Host "Volume removal skipped."
}

Write-Host "Teardown complete."