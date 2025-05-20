
# Static Site Deployment to AWS S3

## Table of Contents
- [Prerequisites](#prerequisites)
- [1. Configure Environment Variables](#1-configure-environment-variables)
- [2. Install AWS CLI](#2-install-aws-cli)
- [3. Configure AWS CLI](#3-configure-aws-cli)
- [4. Create S3 Bucket](#4-create-s3-bucket)
- [5. Verify Bucket Existence](#5-verify-bucket-existence)
- [6. Enable Static Website Hosting](#6-enable-static-website-hosting)
- [7. Configure Public Access](#7-configure-public-access)
- [8. Sample Vite Application](#8-sample-vite-application)
- [9. Build and Upload Site](#9-build-and-upload-site)
- [10. Access Your Site](#10-access-your-site)
- [11. Cleanup Resources](#11-cleanup-resources)


## Prerequisites
- An AWS account with permission to create S3 buckets and modify policies
- AWS CLI installed and configured (see steps 2 & 3)
- Node.js & npm (for Vite)
- Basic familiarity with shell commands

---

## 1. Configure Environment Variables

Create unique bucket name and region variables, then save them to `.env`.

```bash
export BUCKET_NAME=my-static-site-$(date +%s)
export AWS_REGION=us-east-1

# Persist to .env in KEY=VALUE format
printf "BUCKET_NAME=%s\nAWS_REGION=%s\n" \
  "$BUCKET_NAME" "$AWS_REGION" > .env
```

#### Explanation

* **`BUCKET_NAME`**: Uses a timestamp to ensure global uniqueness.
* **`AWS_REGION`**: AWS data-center region (e.g. `us-east-1`).
* Writing to `.env` lets you reload the same settings later without retyping.

---

## 2. Install AWS CLI

Choose the command appropriate for your OS:

```bash
# macOS (Homebrew)
brew install awscli

# Linux (APT)
sudo apt-get update && sudo apt-get install -y awscli

# Windows (Chocolatey)
choco install awscli
```

#### Explanation

Installs the AWS Command Line Interface, which you’ll use to manage S3 and other AWS services from your terminal.

---

## 3. Configure AWS CLI

Run the interactive setup:

```bash
aws configure
```

Enter your:

1. **AWS Access Key ID**
2. **AWS Secret Access Key**
3. **Default region name** (e.g. `us-east-1`)
4. **Default output format** (`json`)

#### Explanation

Stores credentials in `~/.aws/credentials` and default region/output in `~/.aws/config`.

---

## 4. Create S3 Bucket

Make a new bucket in your chosen region:

```bash
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
```

#### Explanation

* **`mb`** = “make bucket.”
* Creates an empty S3 bucket named `$BUCKET_NAME` in `$AWS_REGION`.

---

## 5. Verify Bucket Existence

Use `curl` to confirm the bucket exists (403/301 means it exists; 404 means missing):

```bash
curl -I "https://s3.$AWS_REGION.amazonaws.com/$BUCKET_NAME"
# or
curl -I "https://${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com/"
```

Sample response:

```
HTTP/1.1 403 Forbidden
x-amz-bucket-region: us-east-1
…
```

#### Explanation

* **403 Forbidden**: Bucket exists but isn’t publicly readable.
* **404 Not Found**: Bucket does not exist.

---

## 6. Enable Static Website Hosting

Configure your bucket to serve `index.html` and `404.html`:

```bash
aws s3 website s3://$BUCKET_NAME \
  --index-document index.html \
  --error-document 404.html
```

#### Explanation

Turns your S3 bucket into a simple web host:

* Requests to `/` return `index.html`.
* Missing pages return `404.html`.

---

## 7. Configure Public Access

### 7.1 Disable “Block Public Access”

```bash
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
```

### 7.2 Attach a Bucket Policy

```bash
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy '{
  "Version":"2012-10-17",
  "Statement":[{
    "Sid":"PublicReadGetObject",
    "Effect":"Allow",
    "Principal":"*",
    "Action":"s3:GetObject",
    "Resource":"arn:aws:s3:::'$BUCKET_NAME'/*"
  }]
}'
```

#### Explanation

* AWS blocks public policies by default—step 7.1 lifts that block.
* The policy in 7.2 grants **everyone** (`"Principal":"*"`) permission to fetch any object via `s3:GetObject`.

---

## 8. Sample Vite Application

Scaffold, install, and build a minimal front-end:

```bash
npm create vite@latest sample-vite-app -- --template vanilla
cd sample-vite-app
npm install

# Development server
npm run dev   # http://localhost:5173

# Production build
npm run build # outputs `dist/`
```

#### File Structure

```
sample-vite-app/
├─ index.html
├─ package.json
├─ vite.config.js
└─ src/
   └─ main.js
```

---

## 9. Build and Upload Site

From inside `sample-vite-app/`:

```bash
# Ensure dist/ exists
ls -1 dist

# Sync to S3 (delete obsolete files)
aws s3 sync dist/ s3://$BUCKET_NAME --delete
```

#### Explanation

* **`sync`**: compares local and remote, uploads new/changed files, removes extra remote files (`--delete`).

---

## 10. Access Your Site

Open in browser:

```bash
echo "http://$BUCKET_NAME.s3-website.$AWS_REGION.amazonaws.com"
```

#### Explanation

Uses the S3 **website endpoint** (HTTP only).

---

## 11. Cleanup Resources

Use the provided `cleanup.sh` to remove everything:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

Contents of `cleanup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${BUCKET_NAME:?Need BUCKET_NAME}"
: "${AWS_REGION:?Need AWS_REGION}"

aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

aws s3api delete-bucket-policy --bucket "$BUCKET_NAME"
aws s3api delete-bucket-website --bucket "$BUCKET_NAME"
aws s3 rm "s3://$BUCKET_NAME" --recursive
aws s3 rb "s3://$BUCKET_NAME" --region "$AWS_REGION" --force
```

#### Explanation

1. Disables public-block settings
2. Deletes the bucket policy
3. Removes website configuration
4. Empties and deletes the bucket


Just in case if you want to export the variables from `.env` file to the current shell session, you can use:
```bash
# export all .env variables to the current shell
set -o allexport
source .env
set +o allexport
```
---
