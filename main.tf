terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 3.7.0"
    }
  }
}


resource "random_password" "GitLab_token" {
  length           = 16
  special          = false
  
}


module "gitlab_server" {
  source = "./modules/gitlab_server"
  gitlab_project_name =  var.gitlab_project_name
  aws_region                 = var.aws_region
  gitlab_instance_type       = var.gitlab_instance_type
  key_pair_name              = var.key_pair_name
  gitlab_ami                 = var.gitlab_ami
  gitlab_initial_root_password = var.gitlab_initial_root_password
  tags                       = var.tags
  gitlab_token_value         = var.gitlab_token_value
  vpc_cidr = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_id    = module.vpc.public_subnets[0]
  vpc_id = module.vpc.vpc_id


}


provider "gitlab" {
  token    = var.gitlab_token_value
  base_url = "http://${module.gitlab_server.public_ip}/api/v4"
}


resource "gitlab_project" "example" {
  name        = var.gitlab_project_name
  description = "An example project created with Terraform"
  visibility_level = "private"

  depends_on = [ module.gitlab_server ]
}


resource "null_resource" "clone_repo" {
  
  provisioner "local-exec" {
  command = <<EOT
        REPO_URL=$(echo "${gitlab_project.example.http_url_to_repo}" | sed -e 's|https://||' -e 's|http://||')
        git clone http://root:${var.gitlab_token_value}@$(echo "${gitlab_project.example.http_url_to_repo}" | sed -e 's|https://||' -e 's|http://||') ${var.local_directory_path} 2>&1 | tee clone.log
        touch ${var.local_directory_path}/Jenkinsfile
        cat << 'EOF' > ${var.local_directory_path}/Jenkinsfile
pipeline {
    agent {
        node {
            label 'my-ssh-agent'
        }
    }
    stages {
        stage('Stage 1') {
            steps {
                echo 'Hello world!'
            }
        }
    }
}
EOF

    EOT  
  }
  depends_on = [gitlab_project.example]
  
  }


module "jenkins_server" {
  source            = "./modules/jenkins_server"
  aws_region        = var.aws_region
  key_pair_name     = module.gitlab_server.gitlab_key_pair_name
  jenkins_ami       = var.jenkins_ami
  Jenkins_instance_type = var.Jenkins_instance_type
  jenkins_agent_ami         = var.jenkins_agent_ami
  agent_instance_type = var.agent_instance_type
  public_subnet_id  = module.vpc.public_subnets[0]
  private_subnet_id = module.vpc.private_subnets[0]
  vpc_id            = module.vpc.vpc_id
}


resource "random_password" "Jenkins_token" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "null_resource" "gitlab_jenkins" {
  provisioner "file" {
    source      = "./gitlab_jenkins.sh"
    destination = "/tmp/gitlab_jenkins.sh"


    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(module.gitlab_server.gitlab_key_pair_path)
      host        = module.jenkins_server.public_ip
    }
  }
  provisioner "remote-exec" {
    inline = [
      "export TOKEN=${var.gitlab_token_value}",
      "export GITURL=${gitlab_project.example.http_url_to_repo}",
      "export PROJECTNAME=${var.gitlab_project_name}",
      "export JENKINSTOKEN='${random_password.Jenkins_token.result}'",
      "bash /tmp/gitlab_jenkins.sh"
    ]

  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(module.gitlab_server.gitlab_key_pair_path)
      host        = module.jenkins_server.public_ip
    }
  }
  depends_on = [gitlab_project.example]
}


resource "gitlab_project_hook" "gitlab_hook" {
  project               = gitlab_project.example.id
  url                   = "http://${module.jenkins_server.public_ip}:8080/project/${var.gitlab_project_name}"
  merge_requests_events = true
  push_events = true
  token = tostring(random_password.Jenkins_token.result)
}

