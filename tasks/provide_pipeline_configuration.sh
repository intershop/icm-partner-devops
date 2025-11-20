#!/bin/bash
set -e

################################################################################
# Provide Pipeline Configuration
#
# This script uploads the pipeline configuration file as a build summary.
# The configuration file is displayed in the Azure DevOps build summary tab.
#
# Environment Variables:
#   TEMP_CONFIG_FILE_PATH - Path to the configuration file to upload
################################################################################

echo "##vso[task.uploadsummary]${TEMP_CONFIG_FILE_PATH}"