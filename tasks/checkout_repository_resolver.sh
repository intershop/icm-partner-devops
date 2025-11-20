#!/bin/bash
set -e

################################################################################
# Checkout Repository Resolver
#
# This script resolves the correct branch or tag for a Git repository checkout.
# It handles both tag builds and branch builds, ensuring the repository is at
# the correct commit. For branch builds, it removes tags from newer commits to
# ensure accurate version calculation.
#
# Environment Variables:
#   BUILD_SOURCEVERSION      - The commit SHA to checkout
#   BUILD_SOURCEBRANCH       - The full reference (refs/heads/* or refs/tags/*)
################################################################################

CURRENT_COMMIT="${BUILD_SOURCEVERSION}"
echo "Current commit: ${CURRENT_COMMIT}"

# Check if repository is in detached HEAD state
if ! git symbolic-ref -q HEAD > /dev/null; then
  echo "Repository is in detached HEAD state"
  IS_DETACHED=true
else
  echo "Repository is on branch: $(git branch --show-current)"
  IS_DETACHED=false
fi

# Check if repository is shallow
if [ -f .git/shallow ]; then
  echo "Repository is shallow (shallow fetch was used)"
  IS_SHALLOW=true
else
  echo "Repository is complete (full history available)"
  IS_SHALLOW=false
fi

# Process based on source branch type
if [[ "${BUILD_SOURCEBRANCH}" =~ ^refs/tags/.* ]]; then
  # ============================================================================
  # TAG BUILD: refs/tags/*
  # ============================================================================
  # Extract tag name from reference
  TAG_NAME="${BUILD_SOURCEBRANCH#refs/tags/}"
  echo "Tag build detected: ${TAG_NAME}"
  
  # Fetch the specific tag if not already present locally
  if ! git rev-parse "refs/tags/${TAG_NAME}" >/dev/null 2>&1; then
    echo "Fetching tag ${TAG_NAME}..."
    git fetch origin "refs/tags/${TAG_NAME}:refs/tags/${TAG_NAME}"
  else
    echo "Tag ${TAG_NAME} already exists locally"
  fi
  
  # Checkout the tag
  git checkout "tags/${TAG_NAME}"
  
  # Remove all other tags on the same commit to ensure version uniqueness
  echo "Removing other tags on commit ${CURRENT_COMMIT}..."
  TAGS_TO_REMOVE=$(git tag --points-at "${CURRENT_COMMIT}" | grep -v "^${TAG_NAME}$" || echo "")
  if [[ -n "${TAGS_TO_REMOVE}" ]]; then
    echo "${TAGS_TO_REMOVE}" | xargs -r git tag -d
  else
    echo "No other tags to remove on this commit"
  fi
  
  echo "Successfully checked out tag ${TAG_NAME}"
  
elif [[ "${BUILD_SOURCEBRANCH}" =~ ^refs/heads/ ]]; then
  # ============================================================================
  # BRANCH BUILD: refs/heads/*
  # ============================================================================
  # Extract branch name from full reference
  # Note: BUILD_SOURCEBRANCHNAME is unreliable for branches with slashes (e.g., feature/tools)
  BRANCH="${BUILD_SOURCEBRANCH#refs/heads/}"
  
  echo "Branch build detected: ${BRANCH}"
  
  # Ensure full repository history is available for accurate version calculation
  if [ "${IS_SHALLOW}" = true ]; then
    echo "Unshallowing repository to get full history..."
    if git fetch --unshallow origin "${BRANCH}" 2>&1; then
      echo "Repository unshallowed successfully"
    else
      echo "Warning: Could not unshallow, trying regular fetch..."
      git fetch origin "${BRANCH}"
    fi
  else
    echo "Fetching latest changes for branch ${BRANCH}..."
    git fetch origin "${BRANCH}"
  fi
  
  # Checkout the branch at the specific commit
  if [ "${IS_DETACHED}" = true ]; then
    echo "Creating branch ${BRANCH} from detached HEAD at commit ${CURRENT_COMMIT}..."
    git checkout -B "${BRANCH}" "${CURRENT_COMMIT}"
  else
    echo "Checking out branch ${BRANCH} at commit ${CURRENT_COMMIT}..."
    git checkout "${BRANCH}"
    git reset --hard "${CURRENT_COMMIT}"
  fi
  
  # Remove all tags pointing to the current commit to prevent version conflicts
  echo "Removing all tags on current commit ${CURRENT_COMMIT}..."
  TAGS_ON_CURRENT=$(git tag --points-at "${CURRENT_COMMIT}" 2>/dev/null || echo "")
  if [[ -n "${TAGS_ON_CURRENT}" ]]; then
    echo "Removing tags: ${TAGS_ON_CURRENT}"
    echo "${TAGS_ON_CURRENT}" | xargs -r git tag -d
  else
    echo "No tags to remove on current commit"
  fi
  
  # Remove all tags pointing to commits newer than current commit
  # This ensures SNAPSHOT versions are correctly calculated
  echo "Checking for tags on commits newer than ${CURRENT_COMMIT}..."
  NEWER_COMMITS=$(git rev-list "${CURRENT_COMMIT}..origin/${BRANCH}" 2>/dev/null || echo "")
  if [[ -n "${NEWER_COMMITS}" ]]; then
    echo "Found newer commits, checking for tags to remove..."
    for COMMIT in ${NEWER_COMMITS}; do
      TAGS_ON_COMMIT=$(git tag --points-at "${COMMIT}" 2>/dev/null || echo "")
      if [[ -n "${TAGS_ON_COMMIT}" ]]; then
        echo "Removing tags on commit ${COMMIT}: ${TAGS_ON_COMMIT}"
        echo "${TAGS_ON_COMMIT}" | xargs -r git tag -d
      fi
    done
  else
    echo "No newer commits found or we are at the latest commit"
  fi
  
  echo "Successfully checked out branch ${BRANCH} at commit ${CURRENT_COMMIT}"

else
  # ============================================================================
  # OTHER SOURCES: refs/pull/*, merge commits, etc.
  # ============================================================================
  # No modifications needed for pull requests or other non-standard sources
  echo "No repository modifications performed for source: ${BUILD_SOURCEBRANCH}"
  echo "Repository remains in its current state"
fi

# Show final state
echo "================================"
echo "Final repository state:"
echo "  Current HEAD: $(git rev-parse HEAD)"
echo "  Current branch: $(git branch --show-current || echo 'detached HEAD')"
echo "  Shallow: $([ -f .git/shallow ] && echo 'yes' || echo 'no')"
echo "Remaining tags:"
git tag -l
echo "================================"