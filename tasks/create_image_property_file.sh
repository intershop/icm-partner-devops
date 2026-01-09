#!/bin/bash
set -e

################################################################################
# Create Image Property File
#
# This script reads the labels of a Docker image and creates an imageProperties
# YAML file containing image metadata and build dependencies. The file is then
# uploaded as a pipeline artifact.
#
# Environment Variables:
#   DOCKER_IMAGE_DIRECTORY   - Path to the directory containing imageId files
#   TEMP_CONFIG_FILE_PATH    - Path to the configuration file for appending info
#   TEMP_ID                  - Temporary identifier for artifact naming
################################################################################

# Create a temporary folder for storing intermediate files
TMP_CUSTOM_DIR="$(mktemp -d -t ci-icm-XXXXXXXXXX)"
IMAGE_PROPERTIES_FILE="${TMP_CUSTOM_DIR}/imageProperties.yaml"

# Check if the image directory variable is set
if [ -z "${DOCKER_IMAGE_DIRECTORY}" ]; then
  echo "ERROR: DOCKER_IMAGE_DIRECTORY variable is not set"
  exit 1
fi

# Use 'find' to locate files ending in "-imageId.txt".
# Sort the list by modification time (newest first).
# Only return the first file in the list (the newest).
IMAGE_FILE=$(find "${DOCKER_IMAGE_DIRECTORY}" -name '*-imageId.txt' -type f -printf "%T@ %p\n" | sort -n | tail -1 | cut -f2- -d" ")

# Check if an image file was found
if [ -z "${IMAGE_FILE}" ]; then
  echo "ERROR: No image file found in ${DOCKER_IMAGE_DIRECTORY}"
  exit 1
fi

# Check if the image file exists
if [ ! -f "${IMAGE_FILE}" ]; then
  echo "ERROR: ${IMAGE_FILE} does not exist"
  exit 1
fi

# Extract the image name from the file
IMAGE_NAME=$(tr -d '\n\r' < "${IMAGE_FILE}")

# Check if the image name is valid
if [ -z "${IMAGE_NAME}" ]; then
  echo "ERROR: Image name not found in ${IMAGE_FILE}"
  exit 1
fi

# Extract the repository and tag from the image name
IFS=':' read -r REPOSITORY TAG <<< "${IMAGE_NAME}"

# Check if the repository and tag are valid
if [ -z "${REPOSITORY}" ] || [ -z "${TAG}" ]; then
  echo "ERROR: Invalid image name format in ${IMAGE_FILE}"
  exit 1
fi

# Split image name in registry and image base name
IMAGE_BASE_NAME="${REPOSITORY#*/}"
REGISTRY="${REPOSITORY%%/*}"

# Generate YAML file
cat <<EOF > "${IMAGE_PROPERTIES_FILE}"
images:
  - type: icm-customization
    tag: ${TAG}
    name: ${IMAGE_BASE_NAME}
    registry: ${REGISTRY}
    buildWith: []
EOF

# Read all labels from the Docker image
IMAGE_LABELS="$(docker inspect -f '{{ json .Config.Labels}}' "${IMAGE_NAME}")"

# Check if the label 'build.with' exists
if ! echo "${IMAGE_LABELS}" | jq 'has("build.with")' | grep -q true; then
  echo "The 'build.with' label was not found in ${IMAGE_LABELS}."
  exit 1
fi

# Read the value of the 'build.with' label
BUILD_WITH_VALUE=$(echo "${IMAGE_LABELS}" | jq --arg key "build.with" -r '.[$key]')

# Iterate over the comma-separated list of elements in the 'build.with' label
IFS=',' read -ra ELEMENTS <<< "${BUILD_WITH_VALUE}"
for ELEMENT in "${ELEMENTS[@]}"; do
  echo "## Element: ${ELEMENT}"

  # Check if the label '<ELEMENT>.version' exists in the Docker image
  ELEMENT_KEY="${ELEMENT}.version"
  if ! echo "${IMAGE_LABELS}" | jq --arg key "${ELEMENT_KEY}" 'has($key)' | grep -q true; then
    echo "The '${ELEMENT_KEY}' label was not found in ${IMAGE_LABELS}."
    exit 1
  fi

  # Read the value for the '<ELEMENT>.version' label
  ELEMENT_VALUE=$(echo "${IMAGE_LABELS}" | jq --arg key "${ELEMENT_KEY}" -rc '.[$key]')

  # Check if the ELEMENT_VALUE is not empty
  if [ -z "${ELEMENT_VALUE}" ]; then
    echo "The 'ELEMENT_VALUE' variable is empty."
    exit 1
  fi

  # Write the buildWith image to the IMAGE_PROPERTIES_FILE
  ELEMENT_IMAGE_STRING=$(cat <<EOF
{
  "type": "buildWith",
  "tag": "${ELEMENT_VALUE}",
  "name": "${ELEMENT}",
  "registry": "intershop"
}
EOF
)
  echo "ELEMENT_IMAGE_STRING = $(echo "${ELEMENT_IMAGE_STRING}" | jq -rc)"
  ELEMENT_IMAGE_OBJECT="${ELEMENT_IMAGE_STRING}" \
  yq -i '.images[0].buildWith += eval(strenv(ELEMENT_IMAGE_OBJECT))' "${IMAGE_PROPERTIES_FILE}"
done
  
# Print the contents of the imageProperties file
echo "###### File ${IMAGE_PROPERTIES_FILE} ######"
cat "${IMAGE_PROPERTIES_FILE}"
echo "###### File end ######"

# Upload the imageProperties file as an artifact
echo "##vso[artifact.upload containerfolder=image;artifactname=image_artifacts${TEMP_ID}]${IMAGE_PROPERTIES_FILE}"

# Append created Docker image info to configuration file
cat >> "${TEMP_CONFIG_FILE_PATH}" <<EOF

# Created Docker image
    id:                             ${REPOSITORY}:${TAG}
EOF

# Set pipeline variables for downstream tasks
echo "##vso[task.setvariable variable=tag]${TAG}"
echo "##vso[task.setvariable variable=imageName]${IMAGE_BASE_NAME}"
echo "##vso[task.setvariable variable=registry]${REGISTRY}"