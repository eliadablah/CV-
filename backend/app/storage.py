"""
This is the only file that talks to my database (DynamoDB).

I use one table. Every row has a key called "pk":
  COUNTER#visits  -> the row that counts visits to my site
  MSG#<random id> -> one inquiry from the contact form
"""

COUNTER_KEY = "COUNTER#visits"


class Storage:
    """Saves and reads the visit count and the inquiries."""

    def __init__(self, table_name):
        # I import boto3 here so my tests can run on a computer without it
        import boto3

        self._table = boto3.resource("dynamodb").Table(table_name)

    def increment_visits(self):
        """Add 1 to the visit count and give back the new number."""
        # "ADD" is done inside DynamoDB, so two visitors at the same time are both counted
        result = self._table.update_item(
            Key={"pk": COUNTER_KEY},
            UpdateExpression="ADD visits :one",
            ExpressionAttributeValues={":one": 1},
            ReturnValues="UPDATED_NEW",
        )
        return int(result["Attributes"]["visits"])

    def get_visits(self):
        """Give back the visit count without changing it."""
        result = self._table.get_item(Key={"pk": COUNTER_KEY})
        return int(result.get("Item", {}).get("visits", 0))

    def save_message(self, item):
        """Save one inquiry."""
        self._table.put_item(Item=item)
