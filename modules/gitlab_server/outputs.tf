output "instance_id" {
  description = "The ID of the GitLab server instance"
  value       = aws_instance.gitlab_server.id
}

output "public_ip" {
  description = "The public IP address of the GitLab server"
  value       = aws_instance.gitlab_server.public_ip
}



output "gitlab_key_pair_name" {
  value = aws_key_pair.gitlab_key_pair.key_name
}
output "gitlab_key_pair_path" {
  value = var.key_pair_path
}

output "gitlab_key_pair_public_key" {
  value = aws_key_pair.gitlab_key_pair.public_key
}

output "gitlab_token" {
  value = random_password.GitLab_token.result
}

