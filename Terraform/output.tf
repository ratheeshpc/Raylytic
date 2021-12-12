output "Raylytic_Project_Public_IP" {
  value = aws_instance.RaylyticProject.public_ip
}
output "Raylytic_Project_Public_DNS" {
  value = aws_instance.RaylyticProject.public_dns
}
