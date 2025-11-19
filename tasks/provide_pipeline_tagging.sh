#!/bin/bash
set -e

################################################################################
# Provide Pipeline Tagging
#
# This script adds build tags to the Azure DevOps pipeline based on the source
# type (pull request, tag, branch, or unknown). These tags help categorize and
# filter builds in the pipeline UI.
#
# Environment Variables:
#   BUILD_SOURCEBRANCH - The full Git reference (refs/heads/*, refs/tags/*, refs/pull/*)
################################################################################

echo "Checking Build.SourceBranch: ${BUILD_SOURCEBRANCH}"

if [[ "${BUILD_SOURCEBRANCH}" =~ ^refs/pull/ ]]; then
  echo "##vso[build.addbuildtag]SourceType_Git-PullRequest"
elif [[ "${BUILD_SOURCEBRANCH}" =~ ^refs/tags/ ]]; then
  echo "##vso[build.addbuildtag]SourceType_Git-Tag"
elif [[ "${BUILD_SOURCEBRANCH}" =~ ^refs/heads/ ]]; then
  echo "##vso[build.addbuildtag]SourceType_Git-Branch"
else
  echo "##vso[build.addbuildtag]SourceType_Unknown"
fi