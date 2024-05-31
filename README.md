
# Terraform-GitLab_Jenkins_servers

This project uses Terraform to create a GitLab server and project, a Jenkins server and agent, and connects the servers. The Terraform will connect the local directory that was defined to the GitLab project, and add a basic Jenkinsfile to the directory so you can run a pipeline.


## Prerequisites

Install:

- AWS-cli
- Terraform


## Setup

Create a terraform.tfvars file.

Variables that have to be defined:
 - aws_region
 - project_name
 - local_directory_path



 Variables that can be defined:
 - gitlab_instance_type  (default = "t3.large")
 - key_pair_name    (default = "my-key-pair")
 - gitlab_ami   (default = "ami-0b9714e2ab1e3780e")
 - vpc_cidr (default = "10.0.0.0/16")
 - public_subnet_cidr (default = "10.0.1.0/24")
 - private_subnet_cidr (default = "10.0.2.0/24")
 - Jenkins_instance_type (default = "t3.medium")
 - agent_instance_type (default = "t2.micro")
 - jenkins_agent_ami (default = "ami-07d9b9ddc6cd8dd30")
 - jenkins_ami  (default = "ami-0fc5d935ebf8bc3bc")


## Usage

Running the project is very simple.

```bash

<project directory>/create_all.sh
```

