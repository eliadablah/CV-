"""I build every API answer here so they all look the same."""

import json


def json_response(status_code, body):
    """Make a JSON answer. "no-store" tells browsers and CloudFront not to save a copy."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Cache-Control": "no-store",
        },
        "body": json.dumps(body),
    }
