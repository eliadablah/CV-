"""
The front door of my API. AWS Lambda starts here.

Every request to /api/... lands in this file. All I do here is look at the
request and send it to the right place. The real work is in contact.py and
visitors.py.

My routes:
  GET  /api/health   -> "are you alive?" My deploy pipeline uses this.
  GET  /api/visits   -> read the visit count
  POST /api/visits   -> count one visit
  POST /api/contact  -> save an inquiry and email it to me
"""

import base64
import json
import logging

from app import config
from app.contact import handle_contact
from app.mailer import Mailer
from app.responses import json_response
from app.storage import Storage
from app.visitors import handle_get_visits, handle_record_visit

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# I make these once and reuse them. Lambda keeps them around between requests,
# which makes the next request faster.
_storage = None
_mailer = None


def get_storage():
    global _storage
    if _storage is None:
        _storage = Storage(config.TABLE_NAME)
    return _storage


def get_mailer():
    global _mailer
    if _mailer is None:
        _mailer = Mailer(config.NOTIFY_EMAIL)
    return _mailer


def parse_json_body(event):
    """Turn the request body into a dictionary. I return None if it is missing, too big or not JSON."""
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8", errors="replace")
    if len(body.encode("utf-8")) > config.MAX_BODY_BYTES:
        return None
    try:
        payload = json.loads(body)
    except ValueError:
        return None
    return payload if isinstance(payload, dict) else None


def route(method, path, event):
    """Pick what to do for this request."""
    if (method, path) == ("GET", "/api/health"):
        return json_response(200, {"status": "ok"})
    if (method, path) == ("GET", "/api/visits"):
        return handle_get_visits(get_storage())
    if (method, path) == ("POST", "/api/visits"):
        return handle_record_visit(get_storage())
    if (method, path) == ("POST", "/api/contact"):
        payload = parse_json_body(event)
        if payload is None:
            return json_response(400, {"ok": False, "errors": {"body": "Invalid JSON body."}})
        return handle_contact(payload, get_storage(), get_mailer())
    return json_response(404, {"error": "Not found"})


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path = event.get("rawPath", "").rstrip("/")
    try:
        return route(method, path, event)
    except Exception:
        # I write the full error to my logs. The visitor only sees a short, safe message.
        logger.exception("Something broke on %s %s", method, path)
        return json_response(500, {"error": "Internal server error"})
