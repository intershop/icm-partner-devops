#!/bin/bash
set -e

################################################################################
# Docker Cleanup
#
# This script performs a comprehensive cleanup of Docker resources. It stops
# all running containers and removes all unused containers, networks, images,
# and volumes to free up disk space.
################################################################################

# Stop all containers if any are running
if [[ -n $(docker container ls -a -q) ]]; then
  echo "Stopping all containers..."
  docker container stop $(docker container ls -a -q) || true
fi

# Remove all unused containers, networks, images and volumes
echo "Removing all unused Docker resources..."
docker system prune -a -f --volumes