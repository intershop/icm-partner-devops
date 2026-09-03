#!/bin/bash
set -e

################################################################################
# Check Optional Artifact Directories
#
# These directories are only produced when the corresponding Gradle tasks
# run. This script checks whether they exist, so that artifact publishing can
# be skipped when those tasks are intentionally omitted. A directory that
# exists but has no content is still published; a warning is logged in that
# case. The results are logged and exposed via pipeline variables.
#
# Environment Variables:
#   TEMP_ISH_UNIT_TEST_ARTIFACT_PATH - Absolute path to ISH Unit Test artifacts
#   TEMP_SERVER_LOGS_ARTIFACT_PATH   - Absolute path to server log artifacts
#   TEMP_GEB_TEST_LOG_PATH            - Absolute path to the directory containing Geb test logs
#
# Pipeline Variables set:
#   hasIshUnitArtifacts - 'true' if TEMP_ISH_UNIT_TEST_ARTIFACT_PATH exists, otherwise 'false'
#   hasServerLogs       - 'true' if TEMP_SERVER_LOGS_ARTIFACT_PATH exists, otherwise 'false'
#   hasGebLogs          - 'true' if TEMP_GEB_TEST_LOG_PATH exists, otherwise 'false'
################################################################################

# Returns success if the given directory exists.
directory_exists() {
  local dir="$1"
  [ -d "${dir}" ]
}

# Returns success if the given directory exists and contains at least one entry.
directory_has_content() {
  local dir="$1"
  [ -d "${dir}" ] && [ -n "$(find "${dir}" -mindepth 1 -print -quit)" ]
}

echo "##[section] Checking optional artifact directories"

echo "##[command] Checking: ${TEMP_ISH_UNIT_TEST_ARTIFACT_PATH}"
if directory_exists "${TEMP_ISH_UNIT_TEST_ARTIFACT_PATH}"; then
  HAS_ISH_UNIT_ARTIFACTS="true"
  if ! directory_has_content "${TEMP_ISH_UNIT_TEST_ARTIFACT_PATH}"; then
    echo "##[warning] Directory ${TEMP_ISH_UNIT_TEST_ARTIFACT_PATH} exists but is empty."
  fi
else
  HAS_ISH_UNIT_ARTIFACTS="false"
fi
echo "##vso[task.setvariable variable=hasIshUnitArtifacts]${HAS_ISH_UNIT_ARTIFACTS}"

echo "##[command] Checking: ${TEMP_SERVER_LOGS_ARTIFACT_PATH}"
if directory_exists "${TEMP_SERVER_LOGS_ARTIFACT_PATH}"; then
  HAS_SERVER_LOGS="true"
  if ! directory_has_content "${TEMP_SERVER_LOGS_ARTIFACT_PATH}"; then
    echo "##[warning] Directory ${TEMP_SERVER_LOGS_ARTIFACT_PATH} exists but is empty."
  fi
else
  HAS_SERVER_LOGS="false"
fi
echo "##vso[task.setvariable variable=hasServerLogs]${HAS_SERVER_LOGS}"

echo "##[command] Checking: ${TEMP_GEB_TEST_LOG_PATH}"
if directory_exists "${TEMP_GEB_TEST_LOG_PATH}"; then
  HAS_GEB_LOGS="true"
  if ! directory_has_content "${TEMP_GEB_TEST_LOG_PATH}"; then
    echo "##[warning] Directory ${TEMP_GEB_TEST_LOG_PATH} exists but is empty."
  fi
else
  HAS_GEB_LOGS="false"
fi
echo "##vso[task.setvariable variable=hasGebLogs]${HAS_GEB_LOGS}"

echo "##[section] Result (Directory existence flags)"
echo "hasIshUnitArtifacts = ${HAS_ISH_UNIT_ARTIFACTS}"
echo "hasServerLogs       = ${HAS_SERVER_LOGS}"
echo "hasGebLogs          = ${HAS_GEB_LOGS}"
