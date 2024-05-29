variable "gitlab_instance_type" {
  description = "The type of instance to use for the GitLab server"
  type        = string
  default     = "t3.large"
}

variable "key_pair_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "my-key-pair"
}

variable "key_pair_path" {
  description = "The local path where the key pair will be saved"
  type        = string
  default     = "./my-key-pair.pem"
}


variable "gitlab_ami" {
  description = "The AMI ID for the GitLab server"
  type        = string
  default     = "ami-0b9714e2ab1e3780e"  
}


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


variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}
