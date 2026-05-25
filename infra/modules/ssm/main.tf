resource "aws_ssm_parameter" "rails_master_key" {
  name  = "/${var.project}/${var.env}/rails_master_key"
  type  = "SecureString"
  value = var.rails_master_key

  tags = { Name = "${var.project}-${var.env}-rails-master-key" }

  # Once the parameter is bootstrapped, Terraform stops tracking value
  # changes. This is intentional: CI plans run with TF_VAR_rails_master_key=""
  # (the workflow can't materialize the real key, and shouldn't) — without
  # this, every CI plan would show a phantom diff "wiping" the secret. Rotate
  # the value out-of-band via `aws ssm put-parameter --overwrite` or temporarily
  # remove this ignore_changes for one apply.
  lifecycle {
    ignore_changes = [value]
  }
}
