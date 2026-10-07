variable "project_name" {
  description = "Prefix used in the name of every resource"
  type        = string
  default     = "eliadablahcv"
}

variable "region_name" {
  description = "AWS region. Must stay us-east-1: CloudFront only accepts certificates from there"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Root domain of the existing Route53 hosted zone"
  type        = string
  default     = "eliadablah.com"
}

variable "subdomain" {
  description = "Subdomain for the site (cv -> cv.eliadablah.com)"
  type        = string
  default     = "cv"
}

variable "certificate_domain" {
  description = "Domain on the existing ACM certificate. It must also cover the subdomain above (for example through *.eliadablah.com)"
  type        = string
  default     = null
}

variable "notification_email" {
  description = "Address that receives contact messages, error alarms and budget alerts. Set it in terraform.tfvars"
  type        = string
}

variable "image_tag" {
  description = "Tag of the cv-api image the Lambda function is created with. Later deploys are done by the GitHub Actions pipeline"
  type        = string
  default     = "bootstrap"
}

variable "monthly_budget_usd" {
  description = "Monthly spend limit for the whole AWS account. An email goes out at 80% of it"
  type        = number
  default     = 10
}

variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to deploy through GitHub Actions"
  type        = string
  default     = "eliadablah/eliadablahcv"
}

variable "create_github_oidc_provider" {
  description = "Set to false if this AWS account already has the GitHub Actions OIDC provider"
  type        = bool
  default     = true
}
