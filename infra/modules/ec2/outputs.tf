output "public_ip" {
  value = aws_eip.app.public_ip
}

# Hostname Kamal's proxy claims via Let's Encrypt. sslip.io resolves any
# IP-shaped subdomain back to that IP, so no DNS provisioning is needed.
output "app_host" {
  value = "ip-${replace(aws_eip.app.public_ip, ".", "-")}.sslip.io"
}

output "instance_id" {
  value = aws_instance.app.id
}
