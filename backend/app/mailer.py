"""This file emails me when someone sends an inquiry. It uses Amazon SES."""


class Mailer:
    """Sends inquiry emails to me."""

    def __init__(self, notify_email):
        # I import boto3 here so my tests can run on a computer without it
        import boto3

        self._client = boto3.client("sesv2")
        self._notify_email = notify_email

    def send_contact_notification(self, name, email, company, phone, reason, message):
        """Email the inquiry to me. If I hit Reply, it goes to the visitor."""
        details = [
            f"From: {name} <{email}>",
            f"Company: {company or '-'}",
            f"Phone: {phone or '-'}",
            f"Reason: {reason}",
        ]
        body = "\n".join(details) + f"\n\n{message}"

        self._client.send_email(
            FromEmailAddress=self._notify_email,
            Destination={"ToAddresses": [self._notify_email]},
            ReplyToAddresses=[email],
            Content={
                "Simple": {
                    "Subject": {"Data": f"CV site inquiry from {name} ({reason})"},
                    "Body": {"Text": {"Data": body}},
                }
            },
        )
