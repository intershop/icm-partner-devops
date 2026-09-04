#!/bin/bash
set -e

################################################################################
# Validate Parameters
#
# This script validates all required pipeline parameters and writes them to a
# configuration file. Sensitive information (like passwords) is masked in the
# output. The script exits with an error if any required parameter is missing
# or invalid.
#
# Environment Variables:
#   TEMP_CONFIG_FILE_PATH                   - Output path for the configuration file
#   TEMP_ID                                 - Job identifier (alphanumeric and _ only)
#   TEMP_DOCKER_REPO_ICM_SERVICE_CONNECTION - Docker service connection name
#   TEMP_DOCKER_REPO_ICM                    - Docker repository name
#   TEMP_ACR_SERVICE_CONNECTION             - ACR service connection name
#   TEMP_ACR_SERVICE_CONNECTION_ARM         - ACR ARM service connection name
#   TEMP_ACR                                - Azure Container Registry URL
#   TEMP_ARTIFACTS_FEED                     - Maven/Gradle artifacts feed name
#   TEMP_AGENT_POOL                         - Agent pool name
#   TEMP_CONDITION                          - Job execution condition
#   TEMP_DEPENDS_ON                         - Job dependencies
#   TEMP_PROJECT_PATH                       - Project repository path
#   TEMP_ENV_PATH                           - Environment configuration path
#   TEMP_DIRECTORIES_CONF                   - Directory configuration for Gradle
#   MAPPED_TEMP_REPOSITORIES_CONF           - Repository configuration for Gradle
#   TEMP_GRADLE_USER_HOME                   - Gradle home directory
#   TEMP_CONTAINER_PREFIX                   - Container name prefix
#   TEMP_JOB_TIMEOUT_IN_MINUTES            - Job timeout value
#   TEMP_RUN_GEB_TEST                       - Flag to run Geb tests
#   TEMP_GEB_TEST_TASKS                     - Gradle tasks for Geb tests
#   TEMP_GRADLE_BUILD_TASK                  - Gradle build task
#   TEMP_LOCK_IMAGES                        - Flag to lock images
#   TEMP_PRE_HOOK_TEMPLATE                  - Pre-hook template path
#   TEMP_POST_HOOK_TEMPLATE                 - Post-hook template path
#   TEMP_TEMPLATE_REPOSITORY                - Template repository name
#   TEMP_DOCKERHUB_LOGIN                    - DockerHub login flag
#   TEMP_DOCKERHUB_SERVICE_CONNECTION       - DockerHub service connection
#   TEMP_SONAR_QUBE_ENABLED                 - SonarQube analysis flag
#   TEMP_SQ_GRADLE_PLUGIN_VERSION_CHOICE    - SonarQube plugin version choice
#   TEMP_SONAR_QUBE_PLUGIN_VERSION          - SonarQube plugin version
#   TEMP_CHECK_STYLE_ENABLED                - CheckStyle analysis flag
#   TEMP_PMD_ENABLED                        - PMD analysis flag
#   TEMP_SPOT_BUGS_ENABLED                  - SpotBugs analysis flag
#   TEMP_SPOT_BUGS_PLUGIN_VERSION           - SpotBugs plugin version
#   TEMP_JAVA_VERSION                       - Java version to use
#   TEMP_ISH_UNIT_TEST_ARTIFACT_PATH        - Relative path to ISH Unit Test artifacts
#   TEMP_SERVER_LOGS_ARTIFACT_PATH          - Relative path to server log artifacts
#   TEMP_DOCKER_IMAGE_DIRECTORY              - Relative path to Docker image property files
#   LOG_COLLECTION_DOCKER_LOGS_DIR          - (optional) Path pre-set by the agent where Docker logs are collected;
#                                             when valid, sets pipeline variable TEMP_DOCKER_LOGS_AVAILABLE=true
#                                             and TEMP_DOCKER_LOGS_DIR to the resolved path
################################################################################

# Mask sensitive information in repositoriesConf parameter
# Replace the text between "-PrepoPassword=" and the next space with a masked value
secureRepositoriesConf=$(echo "${MAPPED_TEMP_REPOSITORIES_CONF}" | sed -E 's/(-PrepoPassword=)[^[:space:]]+/\1***MASKED***/g')

echo "##[section] Generating parameter list — available in the Pipeline Extension tab after the run"

# Write all parameters to configuration file
cat > "${TEMP_CONFIG_FILE_PATH}" <<EOF

# Parameters
    id:                             ${TEMP_ID}
    dockerRepoICMServiceConnection: ${TEMP_DOCKER_REPO_ICM_SERVICE_CONNECTION}
    dockerRepoICM:                  ${TEMP_DOCKER_REPO_ICM}
    acrServiceConnection:           ${TEMP_ACR_SERVICE_CONNECTION}
    acrServiceConnectionArm:        ${TEMP_ACR_SERVICE_CONNECTION_ARM}
    acr:                            ${TEMP_ACR}
    artifactsFeed:                  ${TEMP_ARTIFACTS_FEED}
    agentPool:                      ${TEMP_AGENT_POOL}
    condition:                      ${TEMP_CONDITION}
    dependsOn:                      ${TEMP_DEPENDS_ON}
    projectPath:                    ${TEMP_PROJECT_PATH}
    envPath:                        ${TEMP_ENV_PATH}
    directoriesConf:                ${TEMP_DIRECTORIES_CONF}
    repositoriesConf:               ${secureRepositoriesConf}
    gradleUserHome:                 ${TEMP_GRADLE_USER_HOME}
    containerPrefix:                ${TEMP_CONTAINER_PREFIX}
    jobTimeoutInMinutes:            ${TEMP_JOB_TIMEOUT_IN_MINUTES}
    runGebTest:                     ${TEMP_RUN_GEB_TEST}
    gebTestTasks:                   ${TEMP_GEB_TEST_TASKS}
    gradleBuildTask:                ${TEMP_GRADLE_BUILD_TASK}
    lockImages:                     ${TEMP_LOCK_IMAGES}
    preHookTemplate:                ${TEMP_PRE_HOOK_TEMPLATE}
    postHookTemplate:               ${TEMP_POST_HOOK_TEMPLATE}
    templateRepository:             ${TEMP_TEMPLATE_REPOSITORY}

# Dockerhub
    dockerhubLogin:                 ${TEMP_DOCKERHUB_LOGIN}
    dockerhubServiceConnection:     ${TEMP_DOCKERHUB_SERVICE_CONNECTION}

# Code Analysis
    sonarQubeRunAnalysis:           ${TEMP_SONAR_QUBE_ENABLED}
    sqGradlePluginVersionChoice:    ${TEMP_SQ_GRADLE_PLUGIN_VERSION_CHOICE}
    sonarQubeGradlePluginVersion:   ${TEMP_SONAR_QUBE_PLUGIN_VERSION}
    checkStyleRunAnalysis:          ${TEMP_CHECK_STYLE_ENABLED}
    pmdRunAnalysis:                 ${TEMP_PMD_ENABLED}
    spotBugsAnalysis:               ${TEMP_SPOT_BUGS_ENABLED}
    spotbugsGradlePluginVersion:    ${TEMP_SPOT_BUGS_PLUGIN_VERSION}

# Java
    javaVersion:                    ${TEMP_JAVA_VERSION}

# Artifact paths
    ishUnitTestArtifactPath:        ${TEMP_ISH_UNIT_TEST_ARTIFACT_PATH}
    serverLogsArtifactPath:         ${TEMP_SERVER_LOGS_ARTIFACT_PATH}
    dockerImageDirectory:           ${TEMP_DOCKER_IMAGE_DIRECTORY}

# Docker log collection
    LOG_COLLECTION_DOCKER_LOGS_DIR: ${LOG_COLLECTION_DOCKER_LOGS_DIR:-<not set>}
    publishBuildTaskDockerLogs:     ${TEMP_PUBLISH_BUILD_TASK_DOCKER_LOGS}
    
EOF

echo "##[section] Validating required pipeline parameters"

echo "##[command] Checking: acrServiceConnection"
if [ -z "${TEMP_ACR_SERVICE_CONNECTION}" ]; then
  echo "##[error] Parameter acrServiceConnection must not be empty!"
  exit 1
fi

echo "##[command] Checking: artifactsFeed"
if [ -z "${TEMP_ARTIFACTS_FEED}" ]; then
  echo "##[error] Parameter artifactsFeed must not be empty!"
  exit 1
fi

echo "##[command] Checking: dockerRepoICMServiceConnection"
if [ -z "${TEMP_DOCKER_REPO_ICM_SERVICE_CONNECTION}" ]; then
  echo "##[error] Parameter dockerRepoICMServiceConnection must not be empty!"
  exit 1
fi

echo "##[command] Checking: dockerRepoICM"
if [ -z "${TEMP_DOCKER_REPO_ICM}" ]; then
  echo "##[error] Parameter dockerRepoICM must not be empty!"
  exit 1
fi

echo "##[command] Checking: acr (Azure Container Registry URL)"
if [ -z "${TEMP_ACR}" ]; then
  echo "##[error] Parameter acr must not be empty!"
  exit 1
fi

echo "##[command] Checking: projectPath"
if [ -z "${TEMP_PROJECT_PATH}" ]; then
  echo "##[error] Parameter projectPath must not be empty!"
  exit 1
fi

echo "##[command] Checking: envPath"
if [ -z "${TEMP_ENV_PATH}" ]; then
  echo "##[error] Parameter envPath must not be empty!"
  exit 1
fi

echo "##[command] Checking: directoriesConf"
if [ -z "${TEMP_DIRECTORIES_CONF}" ]; then
  echo "##[error] Parameter directoriesConf must not be empty!"
  exit 1
fi

echo "##[command] Checking: repositoriesConf"
if [ -z "${MAPPED_TEMP_REPOSITORIES_CONF}" ]; then
  echo "##[error] Parameter repositoriesConf must not be empty!"
  exit 1
fi

echo "##[command] Checking: gradleUserHome"
if [ -z "${TEMP_GRADLE_USER_HOME}" ]; then
  echo "##[error] Parameter gradleUserHome must not be empty!"
  exit 1
fi

echo "##[command] Checking: containerPrefix"
if [ -z "${TEMP_CONTAINER_PREFIX}" ]; then
  echo "##[error] Parameter containerPrefix must not be empty!"
  exit 1
fi

echo "##[command] Checking: id (must contain only letters, numbers and underscores)"
if [ ! -z "${TEMP_ID}" ]; then
  if echo "${TEMP_ID}" | grep -q '[^a-zA-Z0-9_]'; then
    echo "##[error] Parameter id has to consist of characters, numbers and _ only!"
    exit 1
  fi
fi

echo "##[command] Checking: javaVersion"
if [ -z "${TEMP_JAVA_VERSION}" ]; then
  echo "##[error] Parameter javaVersion must not be empty!"
  exit 1
fi

echo "##[command] Checking: ishUnitTestArtifactPath"
if [ -z "${TEMP_ISH_UNIT_TEST_ARTIFACT_PATH}" ]; then
  echo "##[error] Parameter ishUnitTestArtifactPath must not be empty!"
  exit 1
fi

echo "##[command] Checking: serverLogsArtifactPath"
if [ -z "${TEMP_SERVER_LOGS_ARTIFACT_PATH}" ]; then
  echo "##[error] Parameter serverLogsArtifactPath must not be empty!"
  exit 1
fi

echo "##[command] Checking: dockerImageDirectory"
if [ -z "${TEMP_DOCKER_IMAGE_DIRECTORY}" ]; then
  echo "##[error] Parameter dockerImageDirectory must not be empty!"
  exit 1
fi

echo "##[section] All required parameters are valid"

echo "##[command] Checking: Docker log collection directory (LOG_COLLECTION_DOCKER_LOGS_DIR)"
# Check whether the agent has pre-collected Docker logs and exposed their path.
# Sets pipeline variables consumed by the PublishPipelineArtifact task.
if [[ -n "${LOG_COLLECTION_DOCKER_LOGS_DIR:-}" && -d "$LOG_COLLECTION_DOCKER_LOGS_DIR" ]]; then
  echo "##vso[task.setvariable variable=TEMP_DOCKER_LOGS_AVAILABLE]true"
  echo "##vso[task.setvariable variable=TEMP_DOCKER_LOGS_DIR]$LOG_COLLECTION_DOCKER_LOGS_DIR"
else
  echo "LOG_COLLECTION_DOCKER_LOGS_DIR is not set or not a valid directory: '${LOG_COLLECTION_DOCKER_LOGS_DIR:-}'"
  echo "##vso[task.setvariable variable=TEMP_DOCKER_LOGS_AVAILABLE]false"
fi