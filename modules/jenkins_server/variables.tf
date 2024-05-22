variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
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

variable "Jenkins_instance_type" {
  description = "The type of instance to use for the Jenkins server"
  type        = string
  default     = "t3.medium"
}


variable "jenkins_ami" {
  description = "The AMI ID for the Jenkins server"
  type        = string
  default     = "ami-0fc5d935ebf8bc3bc"  
}

variable "agent_instance_type" {
  description = "Instance type for Jenkins agent"
  type        = string
  default = "t2.micro"
}

variable "jenkins_agent_ami" {
  description = "The AMI ID for the Jenkins agent"
  type        = string
  default     = "ami-07d9b9ddc6cd8dd30"  
}

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

