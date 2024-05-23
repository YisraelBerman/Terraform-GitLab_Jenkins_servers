terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 3.7.0"
    }
  }
}

resource "aws_security_group" "gitlab_sg" {
  name        = "gitlab_sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.gitlab_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.gitlab_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.gitlab_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "random_password" "GitLab_token" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "random_password" "GitLab_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "aws_instance" "gitlab_server" {
  ami                    = var.gitlab_ami
  instance_type          = var.gitlab_instance_type
  key_name               = aws_key_pair.gitlab_key_pair.key_name
  subnet_id              = var.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.gitlab_sg.id]

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
      "expect -c 'spawn sudo gitlab-rake \"gitlab:password:reset\"; expect \"Enter username:\"; send \"root\\r\"; expect \"Enter password:\"; send \"${random_password.GitLab_password.result}\\r\"; expect \"Confirm password:\"; send \"${random_password.GitLab_password.result}\\r\"; interact'",
      "echo 'Creating GitLab access token script'",
      "echo \"user = User.find_by(username: 'root')\" > create_token.rb",
      "echo \"token = user.personal_access_tokens.create!(name: 'Automated Token', scopes: [:api, :read_user, :read_repository, :write_repository, :sudo], expires_at: 30.days.from_now)\" >> create_token.rb",
      "echo \"token.set_token('${random_password.GitLab_token.result}')\" >> create_token.rb",
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


resource "local_file" "gitlab_password" {
  content = random_password.GitLab_password.result
  filename = "gitlab_password.txt"
}
/*
resource "local_file" "token" {
  content = random_password.GitLab_token.result
  filename = "gitlab_token.txt"
}
*/

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


