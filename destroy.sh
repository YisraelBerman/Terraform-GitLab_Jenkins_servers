#!/bin/bash  
terraform destroy -auto-approve -target=gitlab_project.example 
terraform destroy -auto-approve -target=module.vpc.aws_nat_gateway.this

terraform destroy -auto-approve -target=module.jenkins_server
terraform destroy -auto-approve -target=module.gitlab_server 
terraform destroy -auto-approve   