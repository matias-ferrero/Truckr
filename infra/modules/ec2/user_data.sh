#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y docker.io

systemctl enable --now docker
usermod -aG docker ubuntu

# 1 GiB swapfile — t3.micro has 1 GiB RAM and no swap by default, so kamal's
# old+new container cutover (Rails boot, image pull) can OOM the box. With
# swap, slow boots thrash but don't wedge the network stack.
if [ ! -e /swapfile ]; then
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# Ensure SSM agent is running (Canonical's 22.04 AMI ships it as a snap).
# Powers `aws ssm start-session` for break-glass shell access today and
# Kamal's ssh.proxy_command transport in INF-INFRA-00004.
snap start amazon-ssm-agent || true
