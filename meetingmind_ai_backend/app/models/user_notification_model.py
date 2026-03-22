from datetime import datetime

from ..extensions import db


class UserNotification(db.Document):
    user_id = db.StringField(required=True)
    title = db.StringField(required=True)
    body = db.StringField(required=True)
    type = db.StringField(default="system")
    payload = db.DictField(default=dict)
    is_read = db.BooleanField(default=False)
    created_at = db.DateTimeField(default=datetime.utcnow)

    meta = {
        "collection": "UserNotifications",
        "indexes": ["user_id", "is_read", "-created_at"],
    }

