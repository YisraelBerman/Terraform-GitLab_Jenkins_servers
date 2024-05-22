terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 3.7.0"
    }
  }
}



resource "aws_instance" "gitlab_server" {
  ami                    = var.gitlab_ami
  instance_type          = var.gitlab_instance_type
  key_name               = aws_key_pair.gitlab_key_pair.key_name
  subnet_id              = var.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids = [var.vpc_security_group_id]

  tags = var.tags

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu" 
      private_key = tls_private_key.gitlab_key.private_key_pem
      host        = self.public_ip
    }

    inline = [
      "if [ -f /etc/redhat-release ]; then sudo yum install -y expect; else sudo apt-get update && sudo apt-get install -y expect; fi",
      "sudo gitlab-ctl start",
      "while ! sudo gitlab-ctl status | grep -q '^run:'; do echo 'Waiting for GitLab to start...'; sleep 10; done",
      "while ! sudo gitlab-ctl status postgresql | grep -q '^run:'; do echo 'Waiting for PostgreSQL to start...'; sleep 10; done",
      "while ! sudo gitlab-rake db:migrate:status; do echo 'Waiting for database migrations to complete...'; sleep 10; done",
      "echo 'Running password reset script'",
      "expect -c 'spawn sudo gitlab-rake \"gitlab:password:reset\"; expect \"Enter username:\"; send \"root\\r\"; expect \"Enter password:\"; send \"${var.gitlab_initial_root_password}\\r\"; expect \"Confirm password:\"; send \"${var.gitlab_initial_root_password}\\r\"; interact'",
      "echo 'Creating GitLab access token script'",
      "echo \"user = User.find_by(username: 'root')\" > create_token.rb",
      "echo \"token = user.personal_access_tokens.create!(name: 'Automated Token', scopes: [:api, :read_user, :read_repository, :write_repository, :sudo], expires_at: 30.days.from_now)\" >> create_token.rb",
      "echo \"token.set_token('${var.gitlab_token_value}')\" >> create_token.rb",
      "echo \"token.save!\" >> create_token.rb",
      "echo \"File.open('/tmp/gitlab_token.txt', 'w') { |file| file.write(token.token) }\" >> create_token.rb",
      "sudo gitlab-rails runner -e production /home/ubuntu/create_token.rb"
    ]
  } 
}



resource "local_file" "private_key" {
  content  = tls_private_key.gitlab_key.private_key_pem
  filename = var.key_pair_path

  provisioner "local-exec" {
    command = "chmod 400 ${self.filename}"
  }
}

resource "local_file" "token" {
  content = var.gitlab_token_value
  filename = "gitlab_token.txt"
}

resource "local_file" "ip" {
  content = aws_instance.gitlab_server.public_ip
  filename = "gitlab_server_ip.txt"
}



resource "tls_private_key" "gitlab_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "gitlab_key_pair" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.gitlab_key.public_key_openssh
}


