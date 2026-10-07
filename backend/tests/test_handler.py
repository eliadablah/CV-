"""
My tests for cv-api.

I use a fake database and a fake mailer, so the tests run on any computer.
No AWS account and nothing extra to install.

How I run them (from the backend folder):
    python -m unittest discover -s tests -t .
"""

import json
import unittest

from app import handler


class FakeStorage:
    def __init__(self):
        self.visits = 0
        self.messages = []

    def increment_visits(self):
        self.visits += 1
        return self.visits

    def get_visits(self):
        return self.visits

    def save_message(self, item):
        self.messages.append(item)


class FakeMailer:
    def __init__(self, fail=False):
        self.sent = []
        self.fail = fail

    def send_contact_notification(self, name, email, company, phone, reason, message):
        if self.fail:
            raise RuntimeError("SES is down")
        self.sent.append(
            {"name": name, "email": email, "company": company,
             "phone": phone, "reason": reason, "message": message}
        )


def make_event(method, path, body=None):
    """Build a pretend request that looks like the one API Gateway sends."""
    event = {"requestContext": {"http": {"method": method}}, "rawPath": path}
    if body is not None:
        event["body"] = json.dumps(body)
    return event


VALID_MESSAGE = {"name": "Ada", "email": "ada@example.com", "message": "Hello there"}


class HandlerTests(unittest.TestCase):
    def setUp(self):
        self.storage = FakeStorage()
        self.mailer = FakeMailer()
        handler._storage = self.storage
        handler._mailer = self.mailer

    def call(self, method, path, body=None):
        response = handler.lambda_handler(make_event(method, path, body), None)
        return response["statusCode"], json.loads(response["body"])

    def test_health(self):
        self.assertEqual(self.call("GET", "/api/health"), (200, {"status": "ok"}))

    def test_unknown_route_is_404(self):
        status, _ = self.call("GET", "/api/nope")
        self.assertEqual(status, 404)

    def test_post_visits_counts_and_get_does_not(self):
        self.assertEqual(self.call("POST", "/api/visits"), (200, {"visits": 1}))
        self.assertEqual(self.call("POST", "/api/visits"), (200, {"visits": 2}))
        self.assertEqual(self.call("GET", "/api/visits"), (200, {"visits": 2}))

    def test_contact_saves_and_emails(self):
        status, body = self.call("POST", "/api/contact", VALID_MESSAGE)
        self.assertEqual((status, body), (201, {"ok": True}))
        self.assertEqual(len(self.storage.messages), 1)
        self.assertTrue(self.storage.messages[0]["pk"].startswith("MSG#"))
        # I left out the optional fields: company and phone stay blank, reason becomes "Other"
        self.assertEqual(
            self.mailer.sent,
            [{"name": "Ada", "email": "ada@example.com", "company": "",
              "phone": "", "reason": "Other", "message": "Hello there"}],
        )

    def test_contact_keeps_company_phone_and_reason(self):
        full = dict(VALID_MESSAGE, company="Acme Corp", phone="+1 (214) 555-0100", reason="job")
        status, _ = self.call("POST", "/api/contact", full)
        self.assertEqual(status, 201)
        saved = self.storage.messages[0]
        self.assertEqual(
            (saved["company"], saved["phone"], saved["reason"]),
            ("Acme Corp", "+1 (214) 555-0100", "job"),
        )
        self.assertEqual(self.mailer.sent[0]["reason"], "Job opportunity")

    def test_contact_rejects_bad_phone_and_unknown_reason(self):
        bad = dict(VALID_MESSAGE, phone="call me maybe", reason="spam")
        status, body = self.call("POST", "/api/contact", bad)
        self.assertEqual(status, 400)
        self.assertEqual(set(body["errors"]), {"phone", "reason"})
        self.assertEqual(self.storage.messages, [])

    def test_contact_rejects_bad_input(self):
        status, body = self.call(
            "POST", "/api/contact", {"name": "", "email": "not-an-email", "message": ""}
        )
        self.assertEqual(status, 400)
        self.assertEqual(set(body["errors"]), {"name", "email", "message"})
        self.assertEqual(self.storage.messages, [])

    def test_contact_rejects_header_injection_in_name(self):
        bad = dict(VALID_MESSAGE, name="Ada\nBcc: someone@example.com")
        status, _ = self.call("POST", "/api/contact", bad)
        self.assertEqual(status, 400)

    def test_contact_rejects_non_json_body(self):
        event = make_event("POST", "/api/contact")
        event["body"] = "this is not json"
        self.assertEqual(handler.lambda_handler(event, None)["statusCode"], 400)

    def test_honeypot_is_silently_dropped(self):
        status, _ = self.call("POST", "/api/contact", dict(VALID_MESSAGE, website="spam.example"))
        self.assertEqual(status, 201)
        self.assertEqual(self.storage.messages, [])
        self.assertEqual(self.mailer.sent, [])

    def test_contact_still_succeeds_when_email_fails(self):
        handler._mailer = FakeMailer(fail=True)
        status, _ = self.call("POST", "/api/contact", VALID_MESSAGE)
        self.assertEqual(status, 201)
        self.assertEqual(len(self.storage.messages), 1)


if __name__ == "__main__":
    unittest.main()
