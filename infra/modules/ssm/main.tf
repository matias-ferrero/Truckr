resource "aws_ssm_parameter" "rails_master_key" {
  name  = "/${var.project}/${var.env}/rails_master_key"
  type  = "SecureString"
  value = var.rails_master_key

  tags = { Name = "${var.project}-${var.env}-rails-master-key" }
}
