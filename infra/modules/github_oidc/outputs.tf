output "role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the IAM role GitHub Actions assumes — store as GHA_ROLE_ARN repo secret"
}
