output "jenkins_server_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_agent_id" {
  value = aws_instance.jenkins_agent.id
}

output "public_ip" {
  value = aws_instance.jenkins.public_ip
}