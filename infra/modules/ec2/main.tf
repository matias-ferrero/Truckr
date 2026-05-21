data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_iam_role" "ec2" {
  name = "${var.project}-${var.env}-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach AmazonSSMManagedInstanceCore so the box registers with Systems Manager.
# Today: enables `aws ssm start-session` for break-glass shell access.
# Future (INF-INFRA-00004): used as Kamal's ssh.proxy_command transport, letting
# CI deploy without exposing port 22 to GHA's runner IP ranges.
# RAILS_MASTER_KEY and ECR auth are no longer fetched from the instance —
# Kamal injects both from operator-side .kamal/secrets at deploy time.
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.env}-ec2"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "app" {
  ami                    = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = var.key_pair_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
    tags        = { Name = "${var.project}-${var.env}-app" }
  }

  user_data = file("${path.module}/user_data.sh")

  tags = { Name = "${var.project}-${var.env}-app" }

  lifecycle {
    # user_data is only evaluated on first boot; changes here require:
    #   terraform taint module.ec2.aws_instance.app && terraform apply
    ignore_changes = [user_data]
  }
}

# DLM role for EBS snapshot automation
resource "aws_iam_role" "dlm" {
  name = "${var.project}-${var.env}-dlm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "dlm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "ebs_snapshots" {
  description        = "${var.project}-${var.env} daily EBS snapshots"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["INSTANCE"]

    schedule {
      name      = "Daily"
      copy_tags = true

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = 7
      }
    }

    target_tags = {
      Name = "${var.project}-${var.env}-app"
    }
  }
}

# Stable public IP — survives stop/start so the sslip.io hostname keeps
# resolving to the box and Let's Encrypt's HTTP-01 challenges keep succeeding.
resource "aws_eip" "app" {
  domain = "vpc"
  tags   = { Name = "${var.project}-${var.env}-app" }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app.id
}
