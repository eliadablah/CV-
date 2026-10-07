"""
My settings for cv-api.

I read them from environment variables. Terraform sets those on the Lambda
function, so I never type a setting or a secret into the code.
"""

import os

# The DynamoDB table where I keep the visit count and the inquiries
TABLE_NAME = os.environ.get("TABLE_NAME", "eliadablahcv")

# My email address. Inquiries are sent from it and to it.
NOTIFY_EMAIL = os.environ.get("NOTIFY_EMAIL", "")

# I delete inquiries after this many days so I don't keep people's details forever
MESSAGE_TTL_DAYS = int(os.environ.get("MESSAGE_TTL_DAYS", "90"))

# I say no to any request bigger than this (in bytes)
MAX_BODY_BYTES = 10_000
