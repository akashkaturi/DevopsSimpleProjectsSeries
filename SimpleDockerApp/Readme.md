# simple-docker-app

A production-ready FastAPI application, Dockerized with best practices, and deployed to AWS ECR (Elastic Container Registry). Use this guide to:

1. Build and run locally
2. Load environment variables from a `.env` file
3. Create or verify an ECR repository
4. Authenticate and push your image to ECR
5. Pull and run your image from ECR

---

## 📋 Prerequisites

* Docker CLI installed and running
* AWS CLI installed and configured with an IAM user having **ECR** permissions
* A Unix-like shell (bash/zsh)


---

## ⚙️ Configuration

### 1. Create a `.env` file

In your project root, create a file named `.env`:

```dotenv
# .env
AWS_ACCOUNT_ID={AWS_ACCOUNT_ID}   # your 12-digit AWS account ID
AWS_REGION={AWS_REGION}           # e.g. ap-south-1
REPO_NAME={REPO_NAME}             # e.g. simple-docker-app
```

### 2. Add the `load_env.sh` loader script

Create `load_env.sh` alongside your `.env`:

```bash
#!/usr/bin/env bash
# load_env.sh – safely load .env into your shell

if account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null); then
  export AWS_ACCOUNT_ID="$account_id"
else
  echo "❗ Unable to retrieve AWS_ACCOUNT_ID via STS."
  # If .env exists, we’ll load from it; otherwise abort
  if [[ -f "$ENV_FILE" ]]; then
    echo "→ Falling back to ${ENV_FILE}"
  else
    echo "❗ No ${ENV_FILE} found. Exiting." >&2
    exit 1
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

set -o allexport
# shellcheck disable=SC1090
source "$ENV_FILE"
set +o allexport

printf "✅ Environment variables loaded:\n"
printf "  AWS_ACCOUNT_ID=%s\n" "$AWS_ACCOUNT_ID"
printf "  AWS_REGION=%s\n"       "$AWS_REGION"
printf "  REPO_NAME=%s\n"        "$REPO_NAME"
```

Make it executable:

```bash
chmod +x load_env.sh
```

Load your variables:

```bash
source load_env.sh
```

---

## 🚀 Build & Run Locally

1. **Build** the image:

   ```bash
   docker build -t "${REPO_NAME}:latest" .
   ```

2. **Run** the container:

   ```bash
   docker run --rm -p 8000:8000 "${REPO_NAME}:latest"
   ```

3. Visit [http://localhost:8000](http://localhost:8000) — you should see:

   ```json
   { "message": "Hello, world!" }
   ```

---

## ☁️ Deploy to AWS ECR

### 1. Ensure environment variables are loaded

```bash
source load_env.sh
```

### 2. Check for (or create) the ECR repository

```bash
if aws ecr describe-repositories --repository-names "${REPO_NAME}" --region "${AWS_REGION}" > /dev/null 2>&1; then
  echo "→ ECR repository '${REPO_NAME}' already exists in ${AWS_REGION}"
else
  echo "→ Creating ECR repository '${REPO_NAME}' in ${AWS_REGION}'"
  aws ecr create-repository --repository-name "${REPO_NAME}" --region "${AWS_REGION}"
fi
```

### 3. Authenticate Docker to your ECR registry

```bash
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
```

### 4. Build, tag, and push your image

1. **Define the full registry URI**:

   ```bash
   export AWS_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
   ```

2. **Build** (if not already done):

   ```bash
   docker build -t "${REPO_NAME}:latest" .
   ```

3. **Tag** for ECR:

   ```bash
   docker tag "${REPO_NAME}:latest" "${AWS_URI}/${REPO_NAME}:latest"
   ```

4. **Push** to ECR:

   ```bash
   docker push "${AWS_URI}/${REPO_NAME}:latest"
   ```

You should see logs confirming the push:

```
The push refers to repository [469760187267.dkr.ecr.ap-south-1.amazonaws.com/simple-docker-app]
... latest: digest: sha256:... size: ...
```

---

## 🎯 Pull & Run from ECR

1. **Pull** the image from ECR:

   ```bash
   docker pull "${AWS_URI}/${REPO_NAME}:latest"
   ```

2. **Run** it locally:

   ```bash
   docker run --rm -p 8000:8000 "${AWS_URI}/${REPO_NAME}:latest"
   ```

3. Visit [http://localhost:8000](http://localhost:8000) to verify your deployment.

---

## 🧹 Cleanup (Optional)

Remove local images to free space:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

---

## 📝 Conclusion

You’ve now:

* Built a FastAPI app with production‑grade Docker practices
* Used a `.env` loader script to manage credentials safely
* Created and pushed an ECR repository
* Pulled and ran your image from ECR

# Happy coding! 🎉 Good job.
