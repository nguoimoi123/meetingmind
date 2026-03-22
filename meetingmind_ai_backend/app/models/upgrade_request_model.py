from datetime import datetime
from ..extensions import db


class UpgradeRequest(db.Document):
    transaction_id = db.StringField(required=True, unique=True)
    user_id = db.StringField(required=True)
    user_email = db.StringField()
    requested_plan = db.StringField(required=True, choices=["plus", "premium"])
    payment_provider = db.StringField(default="manual")
    amount = db.FloatField()
    currency = db.StringField(default="VND")
    status = db.StringField(
        default="pending",
        choices=["pending", "code_sent", "redeemed", "failed", "revoked"],
    )
    payment_status = db.StringField(
        default="created",
        choices=["created", "pending", "paid", "failed", "cancelled"],
    )
    payment_ref = db.StringField()
    vnp_txn_ref = db.StringField()
    vnp_response_code = db.StringField()
    note = db.StringField()
    issued_code = db.StringField()
    approved_by = db.StringField()
    approved_at = db.DateTimeField()
    paid_at = db.DateTimeField()
    created_at = db.DateTimeField(default=datetime.utcnow)
    updated_at = db.DateTimeField(default=datetime.utcnow)

    meta = {
        "collection": "UpgradeRequests",
        "indexes": [
            "transaction_id",
            "user_id",
            "status",
            "payment_status",
            "requested_plan",
            "issued_code",
            "payment_ref",
            "vnp_txn_ref",
            "-created_at",
        ],
    }
