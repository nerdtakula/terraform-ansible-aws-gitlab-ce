output "public_ip" {
  value       = module.gitlab-ce.public_ip
  description = "IP address of the instance"
}
