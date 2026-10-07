##############################################################################
# My back end: ECR (stores my Docker image) -> Lambda (runs it) <- API Gateway
#
# Why I built it this way: a load balancer, ECS Fargate and NAT gateways cost
# money every hour, even when nobody visits. Lambda and API Gateway only cost
# money when someone uses them. For a CV site that is almost nothing.
##############################################################################

locals {
  api_name = "${var.project_name}-api"
}

# --- ECR: the private place where I store my Docker image ---------------------

resource "aws_ecr_repository" "api" {
  name                 = local.api_name
  image_tag_mutability = "MUTABLE"
  # This lets "terraform destroy" delete it even when it has images in it
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# I only keep the 5 newest images. Old ones are deleted so storage stays cheap.
resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the 5 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

# This allows Lambda to download my image
data "aws_iam_policy_document" "ecr_lambda_pull" {
  statement {
    sid     = "LambdaImagePull"
    actions = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_ecr_repository_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy     = data.aws_iam_policy_document.ecr_lambda_pull.json
}

# --- IAM: the permissions my Lambda gets (as few as possible) ------------------

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${local.api_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# I only allow what my code really does: write its own logs, use its own
# table, and send email from my one address. Nothing else.
data "aws_iam_policy_document" "api" {
  statement {
    sid       = "WriteOwnLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.api.arn}:*"]
  }

  statement {
    sid       = "ReadWriteOwnTable"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.main.arn]
  }

  statement {
    sid       = "SendContactEmail"
    actions   = ["ses:SendEmail"]
    resources = [aws_sesv2_email_identity.owner.arn]
  }
}

resource "aws_iam_role_policy" "api" {
  name   = "${local.api_name}-policy"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.api.json
}

# --- Lambda: runs my Docker image ----------------------------------------------

resource "aws_lambda_function" "api" {
  function_name = local.api_name
  role          = aws_iam_role.api.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.api.repository_url}:${var.image_tag}"
  architectures = ["x86_64"]
  memory_size   = 256
  timeout       = 10

  environment {
    variables = {
      TABLE_NAME       = aws_dynamodb_table.main.name
      NOTIFY_EMAIL     = var.notification_email
      MESSAGE_TTL_DAYS = "90"
    }
  }

  # After the first setup, my GitHub pipeline puts new images on the function.
  # This line stops Terraform from switching it back to the first image.
  lifecycle {
    ignore_changes = [image_uri]
  }

  depends_on = [
    aws_cloudwatch_log_group.api,
    aws_iam_role_policy.api,
    aws_ecr_repository_policy.api,
  ]
}

# --- API Gateway: the public web address that passes requests to my Lambda -----

resource "aws_apigatewayv2_api" "api" {
  name          = local.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# I keep /api at the start of the path, so it is the same path through CloudFront
resource "aws_apigatewayv2_route" "api" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  # My speed limit. It protects me from spam and from a big bill: about 2
  # requests a second, with short bursts of 5. Anything over that is turned
  # away and costs me nothing.
  default_route_settings {
    throttling_rate_limit  = 2
    throttling_burst_limit = 5
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
