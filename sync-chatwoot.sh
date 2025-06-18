#!/bin/bash
# This script clones the Chatwoot repository (if not already cloned),
# checks out a specific tag, and creates a new branch for merging.
# Usage: ./sync-chatwoot.sh <tag>

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tag>"
    exit 1
fi

TAG=$1
REPO_URL="https://github.com/chatwoot/chatwoot.git"
CLONE_DIR="/tmp/chatwoot-sync"

# Clone repository if the directory doesn't exist; otherwise, update tags.
if [ -d "$CLONE_DIR" ]; then
    cd "$CLONE_DIR"
    git fetch --all --tags
else
    git clone "$REPO_URL" "$CLONE_DIR"
    cd "$CLONE_DIR"
fi

# Create and checkout a new branch based on the specified tag.
git checkout tags/"$TAG" -b sync-"$TAG"

echo "Chatwoot repository has been synced to tag $TAG in $CLONE_DIR."

# Optional merge step:
# Uncomment and adjust the following lines to merge the changes into your project repository.
#
# TARGET_DIR="/path/to/your/project"
# cd "$TARGET_DIR"
# git remote add chatwoot "$CLONE_DIR" || true
# git fetch chatwoot
# git merge chatwoot/sync-"$TAG"
#
# echo "Merged Chatwoot tag $TAG into your project at $TARGET_DIR."