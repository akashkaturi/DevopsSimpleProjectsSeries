#!/usr/bin/env bash
set -euo pipefail

# 1. Load your env (AWS_ACCOUNT_ID, AWS_REGION, REPO_NAME)
source load_env.sh

# 2. Compute full registry URI
AWS_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# 3. If the ECR repo exists, delete it; otherwise echo “not exists”
if aws ecr describe-repositories \
     --repository-names "${REPO_NAME}" \
     --region "${AWS_REGION}" \
     > /dev/null 2>&1; then

  echo "→ Deleting ECR repository '${REPO_NAME}' in ${AWS_REGION}…"
  aws ecr delete-repository \
    --repository-name "${REPO_NAME}" \
    --region "${AWS_REGION}" \
    --force

else
  echo "ℹ️  ECR repository '${REPO_NAME}' does not exist in ${AWS_REGION}, skipping delete."
fi

# 4. Remove local Docker images (ignore errors if they’re already gone)
docker image rm \
  "${REPO_NAME}:latest" \
  "${AWS_URI}/${REPO_NAME}:latest" \
  2>/dev/null || true

# 5. Prune all unused Docker data
docker system prune --all --force --volumes

echo "✅ Cleanup complete."
