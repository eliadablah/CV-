"""
The contact form logic. I do three things here:
  1. check what the visitor typed
  2. save the inquiry
  3. email it to me

The database and the mailer are handed in from outside. That way my tests can
hand in fake ones and run without AWS.
"""

import logging
import re
import time
import uuid

from app import config
from app.responses import json_response

logger = logging.getLogger(__name__)

EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
# Numbers and normal phone symbols only. I use a plain space, not \s, so a new line can't sneak in.
PHONE_PATTERN = re.compile(r"^[0-9+()\-. ]{7,20}$")
MAX_NAME = 100
MAX_EMAIL = 254
MAX_COMPANY = 100
MAX_MESSAGE = 2000

# Why the person is writing. The left side must match the dropdown in frontend/index.html.
REASONS = {
    "job": "Job opportunity",
    "freelance": "Freelance or contract work",
    "networking": "Networking",
    "other": "Other",
}


def has_line_break(text):
    return "\n" in text or "\r" in text


def validate(payload):
    """Check the form. I return the cleaned-up fields and a list of what is wrong."""
    errors = {}
    name = str(payload.get("name", "")).strip()
    email = str(payload.get("email", "")).strip()
    company = str(payload.get("company", "")).strip()
    phone = str(payload.get("phone", "")).strip()
    reason = str(payload.get("reason", "") or "other").strip()
    message = str(payload.get("message", "")).strip()

    # I block new lines in one-line fields. They are a known trick for messing with emails.
    if not name or len(name) > MAX_NAME or has_line_break(name):
        errors["name"] = "Name is required (100 characters max)."
    if len(email) > MAX_EMAIL or not EMAIL_PATTERN.match(email):
        errors["email"] = "A valid email is required."
    # Company and phone are optional, so I only check them if they were filled in
    if len(company) > MAX_COMPANY or has_line_break(company):
        errors["company"] = "Company must be 100 characters or fewer."
    if phone and not PHONE_PATTERN.match(phone):
        errors["phone"] = "Phone number is not valid."
    if reason not in REASONS:
        errors["reason"] = "Reason is not one of the listed options."
    if not message or len(message) > MAX_MESSAGE:
        errors["message"] = "Message is required (2000 characters max)."

    fields = {
        "name": name,
        "email": email,
        "company": company,
        "phone": phone,
        "reason": reason,
        "message": message,
    }
    return fields, errors


def handle_contact(payload, storage, mailer):
    """Handle one inquiry from the form and give back the API answer."""
    # My form has a hidden "website" box that people can't see. Only spam bots
    # fill it in. If it has anything in it, I pretend it worked and do nothing.
    if str(payload.get("website", "")).strip():
        return json_response(201, {"ok": True})

    fields, errors = validate(payload)
    if errors:
        return json_response(400, {"ok": False, "errors": errors})

    now = int(time.time())
    storage.save_message(
        {
            "pk": f"MSG#{uuid.uuid4()}",
            **fields,
            "created_at": now,
            "expires_at": now + config.MESSAGE_TTL_DAYS * 86400,
        }
    )

    # The inquiry is already saved. If the email fails, I still tell the visitor
    # it worked, and I write the problem to my logs.
    try:
        # In the email I show the full reason ("Job opportunity"), not the short key ("job")
        mailer.send_contact_notification(**{**fields, "reason": REASONS[fields["reason"]]})
    except Exception:
        logger.exception("Inquiry was saved but the email to me failed")

    return json_response(201, {"ok": True})
