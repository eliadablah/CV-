# Things Terraform prints when it is done. I copy most of them into my GitHub
# repository settings so my deploy pipeline can use them (see docs/DEPLOY.md).

output "site_url" {
  value = "https://${local.frontend_fqdn}"
}

output "frontend_bucket" {
  value = aws_s3_bucket.frontend.id
}

output "frontend_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}

output "lambda_function_name" {
  value = aws_lambda_function.api.function_name
}

output "api_endpoint" {
  description = "The direct address of my API. I use it to test without CloudFront"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "github_deploy_role_arn" {
  value = aws_iam_role.deploy.arn
}
