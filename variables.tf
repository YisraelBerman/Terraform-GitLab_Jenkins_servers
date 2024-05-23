variable "aws_region" {}
variable "gitlab_instance_type" {}
variable "key_pair_name" {}
variable "gitlab_ami" {}
variable "tags" {
  type = map(string)
}
variable "gitlab_token_value" {}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "gitlab_project_name" {
  description = "The name of the GitLab project."
  type        = string
}

variable "jenkins_ami" {
  description = "AMI for Jenkins server"
  type        = string
}

variable "Jenkins_instance_type" {
  description = "Instance type for Jenkins server"
  type        = string
}

variable "jenkins_agent_ami" {
  description = "AMI for Jenkins agent"
  type        = string
}

variable "agent_instance_type" {
  description = "Instance type for Jenkins agent"
  type        = string
}

variable "local_directory_path" {
  description = "The local directory path where the repository will be cloned"
  type        = string
}
