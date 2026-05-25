data "aws_partition" "current" {}

// IAM OIDC providers are account-global per URL — there can only be one for
// token.actions.githubusercontent.com per AWS account. The first env to
// apply (staging) creates it; additional envs reference it via data source
// by setting `create_oidc_provider = false`. Role + policy are still
// per-env (truckr-${env}-github-actions).
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Stable thumbprint for token.actions.githubusercontent.com (documented by GitHub)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

# State migration: the `count` addition above changes the resource address.
# Without the moved block, terraform would propose destroying the existing
# OIDC provider and recreating it under the new address.
moved {
  from = aws_iam_openid_connect_provider.github
  to   = aws_iam_openid_connect_provider.github[0]
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project}-${var.env}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        # Explicit StringEquals list instead of StringLike `repo:.../*`.
        # The wildcard accepted any GitHub ref type — including PRs from
        # forks (sub = repo:fork/...:pull_request). With this list, the
        # role can only be assumed by:
        #   - Pushes/runs on the main branch (apply, deploys)
        #   - Jobs declaring `environment: staging` (Phase 3 apply)
        #   - Jobs declaring `environment: production` (Phase 3 apply, reviewer-gated)
        #   - PR runs from THIS repo (sub format `repo:<org>/<repo>:pull_request`)
        # PR runs from forks have a fork-org sub and stay rejected.
        # infra-plan.yml additionally enforces head.repo.full_name == github.repository
        # so even repo-PR-shaped subs from a forked workflow file can't slip
        # in via PR retarget tricks.
        StringEquals = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
            "repo:${var.github_org}/${var.github_repo}:environment:staging",
            "repo:${var.github_org}/${var.github_repo}:environment:production",
            "repo:${var.github_org}/${var.github_repo}:pull_request",
          ]
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

// Read-only access for `terraform plan` refresh. Without this, plan from CI
// fails on every Get/Describe across the resource types this stack manages
// (iam:GetRole, ec2:DescribeImages, cloudfront:GetDistribution, …). Custom
// allow-list would be a whack-a-mole each time a new module lands; the AWS
// managed ReadOnlyAccess is wider than strictly needed but acceptable in a
// single-purpose project account. Tighten in a follow-up if scope ever
// shrinks (e.g. permissions boundary).
resource "aws_iam_role_policy_attachment" "github_actions_read" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"
}

// Full write access so infra-apply.yml can actually modify resources
// (ec2:RevokeSecurityGroupIngress, iam:UpdateRole, etc.). Required to make
// Phase 3 CD work end-to-end. Same single-purpose-account rationale as
// ReadOnlyAccess above — the real safety boundary is the OIDC trust policy
// (which only grants short-lived tokens to specific sub claims), plus the
// destroy guard in the workflow that bails on any "must be replaced /
// will be destroyed" line in the plan. Tighten to PowerUserAccess +
// custom IAM scope if the account ever hosts other workloads.
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project}-${var.env}-github-actions"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:s3:::${var.tfstate_bucket}",
          "arn:${data.aws_partition.current.partition}:s3:::${var.tfstate_bucket}/*",
        ]
      },
      {
        Sid    = "TerraformLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ]
        Resource = "arn:${data.aws_partition.current.partition}:dynamodb:*:*:table/truckr-tfstate-lock"
      },
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
        ]
        Resource = var.ecr_repository_arn
      },
      {
        Sid    = "SSMDeployDocument"
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ssm:*::document/AWS-RunShellScript",
        ]
      },
      {
        Sid    = "SSMDeployInstance"
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:*:instance/*",
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = var.project
          }
        }
      },
      {
        Sid      = "SSMCommandStatus"
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation"]
        Resource = "*"
      },
      {
        Sid    = "FrontendS3"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          var.frontend_bucket_arn,
          "${var.frontend_bucket_arn}/*",
        ]
      },
      {
        Sid      = "CloudFrontInvalidation"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = var.cloudfront_distribution_arn
      },
      # Below: permissions for Phase 4's Kamal-via-SSM transport flow.
      # backend-deploy.yml pushes an ephemeral SSH key to the EC2 via
      # ec2-instance-connect (60s TTL), then tunnels SSH through SSM Session
      # Manager — no inbound port 22 and no persistent CI keypair.
      {
        Sid      = "EC2InstanceConnect"
        Effect   = "Allow"
        Action   = ["ec2-instance-connect:SendSSHPublicKey"]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:*:instance/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = var.project
          }
        }
      },
      {
        Sid    = "SSMSession"
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:*:instance/*",
          "arn:${data.aws_partition.current.partition}:ssm:*::document/AWS-StartSSHSession",
        ]
        # ResourceTag conditions on ssm:StartSession only apply to the EC2
        # instance ARN, not the document ARN — the document is a global AWS
        # asset. The tag still gates instance access, which is what matters.
        Condition = {
          StringEqualsIfExists = {
            "aws:ResourceTag/Project" = var.project
          }
        }
      },
      {
        Sid    = "EC2DescribeForSSH"
        Effect = "Allow"
        # describe-instances doesn't support resource-level conditions, so
        # this read is account-wide. Read-only and metadata-only.
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      },
    ]
  })
}
