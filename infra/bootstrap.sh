#!/usr/bin/env bash
# Run once before the first terraform apply.
# Usage: ./infra/bootstrap.sh [region]
set -euo pipefail

REGION="${1:-sa-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="truckr-tfstate-${ACCOUNT_ID}"
TABLE="truckr-tfstate-lock"

echo "==> Creating S3 state bucket: $BUCKET (region: $REGION)"
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
else
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
fi

aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "==> Creating DynamoDB lock table: $TABLE"
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "Bootstrap complete."
echo "State bucket: $BUCKET"
echo ""
echo "Next steps:"
echo "  1. Copy infra/envs/staging/terraform.tfvars.example to terraform.tfvars and fill in values"
echo "  2. Copy infra/envs/staging/backend.hcl.example to backend.hcl and set bucket = \"$BUCKET\""
echo "  3. terraform -chdir=infra/envs/staging init -backend-config=backend.hcl"
echo "  4. terraform -chdir=infra/envs/staging plan"
