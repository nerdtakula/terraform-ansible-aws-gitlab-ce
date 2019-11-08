output "public_ip" {
  value       = aws_instance.instance.public_ip
  description = "IP address of the instance"
}
