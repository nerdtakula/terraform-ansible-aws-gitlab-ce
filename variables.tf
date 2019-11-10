variable "region" {
  type        = string
  description = "AWS region in which to provision the AWS resources"
  default     = "us-west-1"
}

variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
  default     = "tak"
}

variable "stage" {
  type        = string
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
  default     = "test"
}

variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'gitlab'"
  default     = "gitlab"
}

variable "description" {
  type        = string
  description = "Will be used as Elastic Compute Cloud application description"
  default     = "Gitlab CE server as Docker container running on Elastic Compute Cloud"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for Gitlab CE master, e.g. 't2.medium'"
  default     = "t2.medium"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to provision the AWS resources"
}

variable "ssh_key_pair" {
  type        = string
  description = "Name of SSH key that will be deployed on Elastic Compute Cloud instances. The key should be present in AWS"
}

variable "private_ssh_key" {
  type        = string
  description = "Name of SSH prvate key that will be used to run Ansible playbook, The key should match the public key present in AWS"
}

variable "ssl_cert_file" {
  type        = string
  description = "SSL cert file for website"
}

variable "ssl_cert_key" {
  type        = string
  description = "SSL cert KEY file for website"
}

variable "ansible_user" {
  type        = string
  description = "username of the root user on the EC2 instance"
  default     = "ubuntu"
}

variable "ansible_vars" {
  type        = map
  description = "variables to pass though to ansible playbook for gitlab instance"
  default     = {}
}
