##############################################################################
# My database: DynamoDB
#
# Why I picked it: a normal database server (like RDS) costs money every hour.
# DynamoDB in "pay per request" mode only costs money when I read or write.
# My data is encrypted for free by AWS, so I don't need to pay for my own key.
##############################################################################

resource "aws_dynamodb_table" "main" {
  name         = var.project_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  # Each inquiry has an "expires_at" time. DynamoDB deletes it for me after that.
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}
