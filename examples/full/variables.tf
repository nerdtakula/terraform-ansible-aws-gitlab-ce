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
