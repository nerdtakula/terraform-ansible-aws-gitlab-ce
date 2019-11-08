/*
 * Set global valirables
 */
locals {
  # General Info
  namespace = "tak"
  name = "git"
  stage = "dev"
  # Domain name to use
  domain = "git.nerdtakula.com"
  # Region to use
  region = "us-west-2" # Oregon
  # Get the list of availability zones
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
}

/*
 * Configure out AWS connection
 */
provider "aws" {
  region  = local.region
}

/*
 * Define the ssh key
 */
resource "aws_key_pair" "ssh_key" {
  key_name   = "${local.service_name}-${local.environment}-ssh-key"
  public_key = file("ssh_key.pub")
}


module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.8.1"
  namespace  = local.service_name
  stage      = local.environment
  name       = "vpc"
  cidr_block = "10.43.0.0/16"
}

module "gitlab-ce" {
  source          = "./modules/gitlab-ce"
  namespace       = local.service_name
  stage           = local.stage
  name            = "service"
  instance_type   = "t2.medium"
  region          = local.region
  ssh_key_pair    = aws_key_pair.ssh_key.key_name
  private_ssh_key = "ssh_key.private"
  vpc_id          = module.vpc.vpc_id
}
