SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

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

set -o allexport
# shellcheck disable=SC1090
source "$ENV_FILE"
set +o allexport

printf "✅ Environment variables loaded:\n"
printf "   AWS_ACCOUNT_ID=%s\n" "$AWS_ACCOUNT_ID"
printf "   AWS_REGION=%s\n"       "$AWS_REGION"
printf "   REPO_NAME=%s\n"        "$REPO_NAME"
