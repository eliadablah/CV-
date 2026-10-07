##############################################################################
# My email: Amazon SES
#
# I send inquiries from my own address to my own address. New AWS accounts can
# only email addresses they have proven they own, and this fits that rule.
#
# After the first "terraform apply", AWS emails me a link. Emails start working
# once I click it.
##############################################################################

resource "aws_sesv2_email_identity" "owner" {
  email_identity = var.notification_email
}
