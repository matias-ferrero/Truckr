// ECR repositories are account-global per name — staging and production
// share a single `${var.project}-backend` registry instead of fighting for
// the name. The first env to apply (staging) creates the repository; later
// envs reference it via data source by setting `create = false`.
//
// Images are still segregated by tag (e.g. `staging-<sha>`, `production-<sha>`)
// so the deploy workflows can pull the right one. The lifecycle policy lives
// on the creating env only.

resource "aws_ecr_repository" "backend" {
  count = var.create ? 1 : 0

  name                 = "${var.project}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.project}-backend" }
}

data "aws_ecr_repository" "backend" {
  count = var.create ? 0 : 1

  name = "${var.project}-backend"
}

resource "aws_ecr_lifecycle_policy" "backend" {
  count = var.create ? 1 : 0

  repository = aws_ecr_repository.backend[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_count_to_keep} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_count_to_keep
      }
      action = { type = "expire" }
    }]
  })
}

# State migrations for the `count` addition above. Without these, terraform
# sees the address change as destroy+create and trips the workflow's
# destroy guard.
moved {
  from = aws_ecr_repository.backend
  to   = aws_ecr_repository.backend[0]
}

moved {
  from = aws_ecr_lifecycle_policy.backend
  to   = aws_ecr_lifecycle_policy.backend[0]
}
