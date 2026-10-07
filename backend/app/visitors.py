"""The visitor counter. The database is handed in so my tests can use a fake one."""

from app.responses import json_response


def handle_record_visit(storage):
    """Count one visit and give back the new total."""
    return json_response(200, {"visits": storage.increment_visits()})


def handle_get_visits(storage):
    """Give back the total without counting a visit."""
    return json_response(200, {"visits": storage.get_visits()})
