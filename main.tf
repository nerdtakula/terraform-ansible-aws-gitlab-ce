/*
 * Set global valirables
 */
locals {
  # General Info
  namespace = "tak"
  name      = "git"
  stage     = "dev"
  region    = "us-west-2" # Oregon
}

/*
 * Configure out AWS connection
 */
provider "aws" {
  region = local.region
}

/*
 * Define the ssh key
 */
resource "aws_key_pair" "ssh_key" {
  key_name   = "${local.namespace}-${local.stage}-${local.name}-ssh-key"
  public_key = file("id_rsa.pub")
}


module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.8.1"
  namespace  = local.namespace
  stage      = local.stage
  name       = local.name
  cidr_block = "10.43.0.0/16"
}

module "gitlab-ce" {
  source          = "./modules/gitlab-ce"
  namespace       = local.namespace
  stage           = local.stage
  name            = local.name
  instance_type   = "t2.medium"
  region          = local.region
  ssh_key_pair    = aws_key_pair.ssh_key.key_name
  private_ssh_key = "ssh_key.private"
  vpc_id          = module.vpc.vpc_id

  ansible_vars = {
    gitlab_version = "12.4.1-ce.0",
    domain_name    = "git.nerdtakula.com"
  }
}
