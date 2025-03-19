output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.polygon_client_lb.dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.polygon_client_repo.repository_url
} 