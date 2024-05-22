output "gitlab_project_url" {
  value = gitlab_project.example.http_url_to_repo
}

output "jenkins_server_IP" {
  value = module.jenkins_server.public_ip
}


output "public_ip" {
  description = "The public IP address of the GitLab server"
  value       = module.gitlab_server.public_ip
}




