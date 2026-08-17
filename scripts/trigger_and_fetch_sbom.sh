#!/usr/bin/env bash
set -euo pipefail

# scripts/trigger_and_fetch_sbom.sh
# Triggers the build-and-scan workflow and downloads the `sbom` artifact when the run completes.
# Requirements: gh CLI (https://cli.github.com/) and authenticated (gh auth login)

OWNER="flesrusselle"
REPO="nginx-ci-demo"
WORKFLOW_FILE="build-and-scan.yml"
BRANCH="main"

# Trigger the workflow
echo "Triggering workflow $WORKFLOW_FILE on $OWNER/$REPO..."
gh workflow run "$WORKFLOW_FILE" --repo "$OWNER/$REPO" --ref "$BRANCH"

# Wait briefly for the run to be created
sleep 3

# Get the latest run ID for the workflow on branch
RUN_ID=""
for i in {1..60}; do
  echo "Checking for workflow run (attempt $i) ..."
  RUN_ID=$(gh run list --repo "$OWNER/$REPO" --workflow "$WORKFLOW_FILE" --branch "$BRANCH" --limit 1 --json databaseId,status,conclusion --jq '.[0].databaseId') || true
  if [[ -n "$RUN_ID" && "$RUN_ID" != "null" ]]; then
    echo "Found run ID: $RUN_ID"
    break
  fi
  sleep 2
done

if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
  echo "Failed to find workflow run for $WORKFLOW_FILE"
  exit 1
fi

# Poll the run status until completed
for i in {1..300}; do
  STATUS=$(gh run view "$RUN_ID" --repo "$OWNER/$REPO" --json status,conclusion --jq '.status')
  CONCLUSION=$(gh run view "$RUN_ID" --repo "$OWNER/$REPO" --json status,conclusion --jq '.conclusion')
  echo "Run status: $STATUS, conclusion: $CONCLUSION"
  if [[ "$STATUS" == "completed" ]]; then
    break
  fi
  sleep 5
done

# Download the sbom artifact
mkdir -p artifacts
echo "Downloading sbom artifact for run $RUN_ID..."
# If artifact doesn't exist, gh will return non-zero; ignore failure and report
if gh run download "$RUN_ID" --repo "$OWNER/$REPO" --name sbom -D artifacts; then
  echo "SBOM downloaded to artifacts/"
else
  echo "SBOM artifact not found for run $RUN_ID. Check the workflow logs in Actions." >&2
  exit 1
fi

echo "Done."
