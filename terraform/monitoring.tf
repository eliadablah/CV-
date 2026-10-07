##############################################################################
# How I watch my site and my bill: CloudWatch, SNS and AWS Budgets
##############################################################################

# --- Logs: I keep them for 14 days, then they are deleted so they stay free -----

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${local.api_name}"
  retention_in_days = 14
}

# --- Alerts: SNS emails me when something goes wrong ----------------------------

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# After the first "terraform apply", AWS emails me a link I have to click to turn this on
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# --- Alarm: tell me if my API has an error --------------------------------------

resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "${local.api_name}-errors"
  alarm_description   = "My cv-api Lambda had at least one error in the last 5 minutes"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
  }
}

# --- Budget: email me before my bill gets too high ------------------------------

# This watches my whole AWS account, not just this project. So if I forget to
# turn something off from another lab, I still get the warning.
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.notification_email]
  }
}
