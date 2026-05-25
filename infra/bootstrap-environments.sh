#!/usr/bin/env bash
# Bootstrap GitHub Environments + repo secrets/variables for INF-INFRA-00004's
# CD workflows (Phase 3 onward). Idempotent — safe to run multiple times.
#
# Prerequisites:
#   - `gh` CLI authenticated (`gh auth status`) with admin scope on the repo
#   - AWS_PROFILE pointing at the staging account (only needed if GHA_ROLE_ARN
#     is not yet set; otherwise we read the role ARN from the existing secret
#     state which is opaque, so we don't try to verify it)
#
# Sets up:
#   - GitHub Environment `staging`  — no reviewers, no wait timer
#   - GitHub Environment `production` — required reviewer = repo owner
#   - Repo secret  GHA_ROLE_ARN   — from `terraform output -raw github_actions_role_arn`
#   - Repo variable TFSTATE_BUCKET — from `infra/envs/staging/backend.hcl`
#
# Does NOT touch SSH_CIDR — the operator sets that one manually with their real
# public IP because the script can't know it:
#   gh secret set SSH_CIDR --body "$(curl -s ifconfig.me)/32"

set -euo pipefail

REPO_DEFAULT="tcorzo/fiuba-gestion-tp"
REPO="${REPO:-$REPO_DEFAULT}"

OWNER="${REPO%/*}"

echo "==> Targeting repository: $REPO"

# --- GitHub Environments -----------------------------------------------------

echo "==> Ensuring environment 'staging' exists (no reviewers, no wait timer)"
gh api -X PUT "repos/$REPO/environments/staging" \
  --silent \
  -f wait_timer=0 \
  || { echo "FAILED to create/update staging environment"; exit 1; }

echo "==> Ensuring environment 'production' exists with required reviewer = $OWNER"
OWNER_ID=$(gh api "users/$OWNER" --jq .id)
gh api -X PUT "repos/$REPO/environments/production" \
  --silent \
  -f wait_timer=0 \
  -F "reviewers[][type]=User" \
  -F "reviewers[][id]=$OWNER_ID" \
  || { echo "FAILED to create/update production environment"; exit 1; }

# --- Repo variable: TFSTATE_BUCKET -------------------------------------------

if gh variable list --repo "$REPO" | grep -q '^TFSTATE_BUCKET'; then
  echo "==> Repo variable TFSTATE_BUCKET already set — skipping"
else
  if [ -f "infra/envs/staging/backend.hcl" ]; then
    BUCKET=$(awk -F'"' '/^bucket/{print $2}' infra/envs/staging/backend.hcl)
  else
    echo "::warning:: infra/envs/staging/backend.hcl not found; cannot derive TFSTATE_BUCKET"
    BUCKET=""
  fi
  if [ -n "$BUCKET" ]; then
    echo "==> Setting repo variable TFSTATE_BUCKET=$BUCKET"
    gh variable set TFSTATE_BUCKET --body "$BUCKET" --repo "$REPO"
  else
    echo "::warning:: Set TFSTATE_BUCKET manually: gh variable set TFSTATE_BUCKET --body 'truckr-tfstate-<account-id>' --repo $REPO"
  fi
fi

# --- Repo secret: GHA_ROLE_ARN -----------------------------------------------

if gh secret list --repo "$REPO" | grep -q '^GHA_ROLE_ARN'; then
  echo "==> Repo secret GHA_ROLE_ARN already set — skipping"
else
  if command -v terraform >/dev/null 2>&1 && [ -d "infra/envs/staging" ]; then
    if ROLE_ARN=$(terraform -chdir=infra/envs/staging output -raw github_actions_role_arn 2>/dev/null); then
      echo "==> Setting repo secret GHA_ROLE_ARN from terraform output"
      gh secret set GHA_ROLE_ARN --body "$ROLE_ARN" --repo "$REPO"
    else
      echo "::warning:: terraform output failed; set GHA_ROLE_ARN manually:"
      echo "  ROLE_ARN=\$(terraform -chdir=infra/envs/staging output -raw github_actions_role_arn)"
      echo "  gh secret set GHA_ROLE_ARN --body \"\$ROLE_ARN\" --repo $REPO"
    fi
  else
    echo "::warning:: terraform not available; set GHA_ROLE_ARN manually"
  fi
fi

# --- Reminder ----------------------------------------------------------------

if ! gh secret list --repo "$REPO" | grep -q '^SSH_CIDR'; then
  cat <<EOF

==> NOTE: repo secret SSH_CIDR is NOT set.

Without it, CI workflows fall back to TEST-NET-1 (192.0.2.0/32), which will
cause a "1 to change" diff on every \`terraform plan\` because the actual SG
rule on AWS is set to your operator IP. Set it once:

  gh secret set SSH_CIDR --body "\$(curl -s ifconfig.me)/32" --repo $REPO

EOF
fi

echo "==> Bootstrap complete."
