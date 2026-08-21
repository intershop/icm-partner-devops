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

echo "##[section] Validating required environment variables"

echo "##[command] Checking: DOCKER_IMAGE_DIRECTORY"
if [ -z "${DOCKER_IMAGE_DIRECTORY}" ]; then
  echo "##[error] DOCKER_IMAGE_DIRECTORY variable is not set"
  exit 1
fi

echo "##[command] Locating image ID file in: ${DOCKER_IMAGE_DIRECTORY}"
IMAGE_FILE=$(find "${DOCKER_IMAGE_DIRECTORY}" -name '*-imageId.txt' -type f -printf "%T@ %p\n" | sort -n | tail -1 | cut -f2- -d" ")

if [ -z "${IMAGE_FILE}" ]; then
  echo "##[error] No image file found in ${DOCKER_IMAGE_DIRECTORY}"
  exit 1
fi

if [ ! -f "${IMAGE_FILE}" ]; then
  echo "##[error] ${IMAGE_FILE} does not exist"
  exit 1
fi

echo "##[command] Reading image name from: ${IMAGE_FILE}"
IMAGE_NAME=$(tr -d '\n\r' < "${IMAGE_FILE}")

if [ -z "${IMAGE_NAME}" ]; then
  echo "##[error] Image name not found in ${IMAGE_FILE}"
  exit 1
fi

# Extract the repository and tag from the image name
IFS=':' read -r REPOSITORY TAG <<< "${IMAGE_NAME}"

if [ -z "${REPOSITORY}" ] || [ -z "${TAG}" ]; then
  echo "##[error] Invalid image name format in ${IMAGE_FILE}"
  exit 1
fi

# Split image name in registry and image base name
IMAGE_BASE_NAME="${REPOSITORY#*/}"
REGISTRY="${REPOSITORY%%/*}"
echo "##[command] Image resolved — registry: ${REGISTRY}, name: ${IMAGE_BASE_NAME}, tag: ${TAG}"

echo "##[section] Generating imageProperties YAML file"
echo "##[command] Writing: ${IMAGE_PROPERTIES_FILE}"
cat <<EOF > "${IMAGE_PROPERTIES_FILE}"
images:
  - type: icm-customization
    tag: ${TAG}
    name: ${IMAGE_BASE_NAME}
    registry: ${REGISTRY}
    buildWith: []
EOF

echo "##[section] Reading Docker image labels"
echo "##[command] Inspecting image: ${IMAGE_NAME}"
IMAGE_LABELS="$(docker inspect -f '{{ json .Config.Labels}}' "${IMAGE_NAME}")"

echo "##[command] Checking for 'build.with' label"
if ! echo "${IMAGE_LABELS}" | jq 'has("build.with")' | grep -q true; then
  echo "##[error] The 'build.with' label was not found in image labels"
  exit 1
fi

BUILD_WITH_VALUE=$(echo "${IMAGE_LABELS}" | jq --arg key "build.with" -r '.[$key]')
echo "##[command] build.with = ${BUILD_WITH_VALUE}"

echo "##[section] Processing buildWith dependencies"
IFS=',' read -ra ELEMENTS <<< "${BUILD_WITH_VALUE}"
for ELEMENT in "${ELEMENTS[@]}"; do
  echo "##[command] Processing element: ${ELEMENT}"

  ELEMENT_KEY="${ELEMENT}.version"
  if ! echo "${IMAGE_LABELS}" | jq --arg key "${ELEMENT_KEY}" 'has($key)' | grep -q true; then
    echo "##[error] Label '${ELEMENT_KEY}' was not found in image labels"
    exit 1
  fi

  ELEMENT_VALUE=$(echo "${IMAGE_LABELS}" | jq --arg key "${ELEMENT_KEY}" -rc '.[$key]')

  if [ -z "${ELEMENT_VALUE}" ]; then
    echo "##[error] Value for label '${ELEMENT_KEY}' is empty"
    exit 1
  fi

  echo "##[command] ${ELEMENT_KEY} = ${ELEMENT_VALUE}"
  ELEMENT_IMAGE_STRING=$(cat <<EOF
{
  "type": "buildWith",
  "tag": "${ELEMENT_VALUE}",
  "name": "${ELEMENT}",
  "registry": "intershop"
}
EOF
)
  echo "##[command] buildWith entry: $(echo "${ELEMENT_IMAGE_STRING}" | jq -rc)"
  ELEMENT_IMAGE_OBJECT="${ELEMENT_IMAGE_STRING}" \
  yq -i '.images[0].buildWith += eval(strenv(ELEMENT_IMAGE_OBJECT))' "${IMAGE_PROPERTIES_FILE}"
done
  
echo "##[section] imageProperties file contents"
cat "${IMAGE_PROPERTIES_FILE}"

echo "##[section] Uploading imageProperties file as pipeline artifact"
echo "##[command] Artifact: image_artifacts${TEMP_ID}"
echo "##vso[artifact.upload containerfolder=image;artifactname=image_artifacts${TEMP_ID}]${IMAGE_PROPERTIES_FILE}"

echo "##[section] Appending image info to configuration file"
cat >> "${TEMP_CONFIG_FILE_PATH}" <<EOF

# Created Docker image
    id:                             ${REPOSITORY}:${TAG}
EOF

echo "##[command] Setting pipeline variable: tag=${TAG}"
echo "##vso[task.setvariable variable=tag]${TAG}"

echo "##[section] Create image property file complete"
echo "##vso[task.setvariable variable=imageName]${IMAGE_BASE_NAME}"
echo "##vso[task.setvariable variable=registry]${REGISTRY}"