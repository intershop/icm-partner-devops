#!/bin/bash
set -e

################################################################################
# Write Docker Logs
#
# This script extracts and saves Docker container logs to text files for
# debugging and troubleshooting purposes. It creates log files for web
# application (wa), web application admin (waa), and application server (as)
# containers.
#
# Environment Variables:
#   TEMP_CONTAINER_PREFIX - Prefix for container names
#   TEMP_GEB_LOG_DIR      - Geb project path where logs should be saved
################################################################################

echo "Listing running containers..."
docker ps

# Create directory for log files
mkdir -p "${TEMP_GEB_LOG_DIR}"

# Extract web application container logs
echo "Extracting log from ${TEMP_CONTAINER_PREFIX}-wa..."
docker logs "${TEMP_CONTAINER_PREFIX}-wa" &> "${TEMP_GEB_LOG_DIR}"/wa_log.txt || echo "Failed to extract wa logs"

# Extract web application admin container logs
echo "Extracting log from ${TEMP_CONTAINER_PREFIX}-waa..."
docker logs "${TEMP_CONTAINER_PREFIX}-waa" &> "${TEMP_GEB_LOG_DIR}"/waa_log.txt || echo "Failed to extract waa logs"
# Extract application server container logs
echo "Extracting log from ${TEMP_CONTAINER_PREFIX}-as..."
docker logs "${TEMP_CONTAINER_PREFIX}-as" &> "${TEMP_GEB_LOG_DIR}"/as_log.txt || echo "Failed to extract as logs"

echo "Docker logs successfully written to ${TEMP_GEB_LOG_DIR}"
