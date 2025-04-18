# (Previous script parts)...

# Show final Docker status
Write-Host "Current Docker Resources:" -ForegroundColor Magenta
Write-Host "------------------------"
Write-Host "CONTAINERS:" -ForegroundColor Cyan
docker ps -a
Write-Host ""
Write-Host "IMAGES:" -ForegroundColor Cyan
docker images
Write-Host ""
Write-Host "VOLUMES:" -ForegroundColor Cyan
docker volume ls
Write-Host ""
Write-Host "NETWORKS:" -ForegroundColor Cyan
docker network ls
Write-Host ""
Write-Host "------------------------" # <<< **DELETE AND RE-TYPE THIS LINE MANUALLY**
# End of Script