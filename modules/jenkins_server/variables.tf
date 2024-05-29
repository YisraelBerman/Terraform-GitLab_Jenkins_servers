
variable "key_pair_name" {
  description = "The name of the SSH key pair"
  type        = string
}

variable "key_pair_path" {
  description = "The local path where the key pair will be saved"
  type        = string
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

