#!/bin/bash
set -e

################################################################################
# Set Image Attributes
#
# This script updates the attributes of a Docker image in Azure Container
# Registry (ACR). It sets the image to be immutable by disabling both delete
# and write operations.
#
# Environment Variables:
#   REGISTRY    - The ACR registry name (without .azurecr.io)
#   IMAGE_NAME  - The image name within the registry
#   TAG         - The image tag to update
################################################################################

# Update the image attributes to make it immutable
az acr repository update \
  --name "${REGISTRY}" \
  --image "${IMAGE_NAME}:${TAG}" \
  --delete-enabled false \
  --write-enabled false