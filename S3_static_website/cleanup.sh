#!/usr/bin/env bash
set -euo pipefail

: "${BUCKET_NAME:?Need BUCKET_NAME env var}"
: "${AWS_REGION:?Need AWS_REGION env var}"

# 1. Disable Block Public Access
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

# 2. Remove bucket policy
aws s3api delete-bucket-policy \
  --bucket "$BUCKET_NAME"

# 3. Remove static-website config
aws s3api delete-bucket-website \
  --bucket "$BUCKET_NAME"

# 4. Delete all objects (and versions, if versioning enabled)
aws s3 rm "s3://$BUCKET_NAME" --recursive

# 5. Delete the bucket
aws s3 rb "s3://$BUCKET_NAME" --region "$AWS_REGION" --force
