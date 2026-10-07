# Terraform keeps a file that remembers what it built (the "state").
# I store it in S3, not on my laptop, so it is safe and backed up.
# This project has its own key, so it never mixes with my other projects.
terraform {
  backend "s3" {
    bucket       = "terraform-nvrdel-2026"
    key          = "eliadablahcv/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
