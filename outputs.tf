output "gitlab_project_url" {
  value = gitlab_project.example.http_url_to_repo
}

output "jenkins_server_IP" {
  value = module.jenkins_server.public_ip
}


output "GitLab_server_public_ip" {
  description = "The public IP address of the GitLab server"
  value       = module.gitlab_server.public_ip
}


output "Jenkins_server_public_ip" {
  description = "The public IP address of the Jenkins server"
  value       = module.jenkins_server.public_ip
}



