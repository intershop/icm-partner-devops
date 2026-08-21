#!/bin/bash
set -e

################################################################################
# Docker Cleanup
#
# This script performs a comprehensive cleanup of Docker resources. It stops
# all running containers and removes all unused containers, networks, images,
# and volumes to free up disk space.
################################################################################

echo "##[section] Stopping all running Docker containers"

container_ids=$(docker container ls -a -q)
if [[ -n "${container_ids}" ]]; then
  echo "##[command] Stopping containers: ${container_ids}"
  echo "${container_ids}" | xargs docker container stop || true
  echo "##[command] All containers stopped"
else
  echo "No running containers found — skipping stop"
fi

echo "##[section] Removing all unused Docker resources"
docker system prune -a -f --volumes
echo "##[section] Docker cleanup complete"