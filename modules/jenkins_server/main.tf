provider "aws" {
  region = var.aws_region
}


resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_jenkins" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.jenkins_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}







resource "aws_instance" "jenkins" {
  ami           = var.jenkins_ami
  instance_type = var.Jenkins_instance_type
  key_name      = var.key_pair_name
  subnet_id     = var.public_subnet_id
  associate_public_ip_address = true


  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  provisioner "local-exec" {
    command = "sed -i 's|agent_ip_here|${aws_instance.jenkins_agent.private_ip}|g' ${path.module}/jenkins_setup.sh"
  }
  provisioner "file" {
    source      = "${var.key_pair_path}"
    destination = "/tmp/your_key.pem"  
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.key_pair_path)
      host        = self.public_ip
    }
}
  provisioner "file" {
    source      = "${path.module}/jenkins_setup.sh"
    destination = "/tmp/jenkins_setup.sh"


    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.key_pair_path)
      host        = self.public_ip
    }
  }

  
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/jenkins_setup.sh",
      "/tmp/jenkins_setup.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.key_pair_path)
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "scp -i ${var.key_pair_path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${self.public_ip}:/home/ubuntu/jenkins_initial_admin_password.txt ./jenkins_initial_admin_password.txt"
  }




  provisioner "local-exec" {
    command = "sed -i 's|${aws_instance.jenkins_agent.private_ip}|agent_ip_here|g' ${path.module}/jenkins_setup.sh"
  }

  tags = {
    Name = "JenkinsServer"
  }


}

resource "aws_instance" "jenkins_agent" {
  ami           = var.jenkins_agent_ami
  instance_type = var.agent_instance_type
  key_name      = var.key_pair_name
  subnet_id     = var.private_subnet_id


  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y openjdk-11-jdk
              EOF

  tags = {
    Name = "JenkinsAgent"
  }
}
