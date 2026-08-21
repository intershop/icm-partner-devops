#!/bin/bash
set -e

################################################################################
# Notify on Pipeline Failure
#
# This script is executed when the pipeline job has failed.
# It prints a structured warning message to the pipeline log, informing
# developers about the available pipeline artifacts for troubleshooting.
#
# Environment Variables:
#   TEMP_ID                          - Job identifier suffix used in artifact names
#   TEMP_RUN_GEB_TEST                - Whether Geb tests were executed (true/false)
#   TEMP_PUBLISH_BUILD_TASK_DOCKER_LOGS - Whether Docker logs from the build task
#                                        were published (true/false)
################################################################################

echo "##vso[task.logissue type=error]The pipeline job failed. Container and build logs have been collected and are available as pipeline artifacts."
echo ""
echo "##[section] Troubleshooting: Log Artifacts"
echo "##[command] The following artifacts were published and can be accessed via the pipeline run's 'Artifacts' button (top right of the run summary):"
echo ""
echo "  - build_artifacts${TEMP_ID}"
echo "      -> Server/application logs from the Gradle build step"
echo ""
echo "  - ishUnitTest_artifacts${TEMP_ID}"
echo "      -> ISH unit test runner output"
echo ""
if [[ "${TEMP_RUN_GEB_TEST}" == "True" ]]; then
  echo "  - geb_test_log_files${TEMP_ID}"
  echo "      -> Geb UI test logs and screenshots"
  echo ""
fi
if [[ "${TEMP_PUBLISH_BUILD_TASK_DOCKER_LOGS}" == "True" ]]; then
  echo "  - build_artifacts_docker_logs${TEMP_ID}"
  echo "      -> Docker container logs collected during the Gradle build task"
  echo "         (only present when the agent exposes LOG_COLLECTION_DOCKER_LOGS_DIR)"
  echo ""
fi
echo "##[command] How to access artifacts:"
echo "  1. Open the pipeline run in Azure DevOps."
echo "  2. In the run summary, locate the 'Related' column in the upper section."
echo "  3. Click the published artifacts link shown there."
echo "  4. Select the relevant artifact folder from the list above."
echo ""
echo "##[command] Additional configuration details are available in the 'Extensions' tab of this pipeline run."
