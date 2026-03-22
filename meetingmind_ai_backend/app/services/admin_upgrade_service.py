from datetime import datetime
from typing import Optional, Tuple

from flask import request, session

from app.config import Config
from app.extensions import socketio
from app.models.upgrade_request_model import UpgradeRequest
from app.models.upgrade_code_model import UpgradeCode
from app.models.user_model import User
from app.services.notification_center_service import create_user_notification
from app.services.plan_service import create_upgrade_codes


def _extract_admin_key() -> str:
    return (
        request.headers.get("X-Admin-Key")
        or request.args.get("admin_key")
        or ""
    ).strip()


def is_admin_authorized() -> bool:
    configured = (Config.ADMIN_DASHBOARD_KEY or "").strip()
    if not configured:
        return False
    if session.get("admin_logged_in") is True:
        return True
    return _extract_admin_key() == configured


def webhook_secret_matches() -> bool:
    configured = (Config.PAYMENT_WEBHOOK_SECRET or "").strip()
    if not configured:
        return True
    incoming = (request.headers.get("X-Webhook-Secret") or "").strip()
    return incoming == configured


def create_upgrade_request(
    *,
    transaction_id: str,
    user_id: str,
    requested_plan: str,
    user_email: Optional[str] = None,
    payment_provider: str = "manual",
    amount: Optional[float] = None,
    currency: str = "VND",
    note: Optional[str] = None,
) -> Tuple[Optional[UpgradeRequest], Optional[str]]:
    if not transaction_id:
        return None, "transaction_id is required"
    if not user_id:
        return None, "user_id is required"
    if requested_plan not in ("plus", "premium"):
        return None, "Invalid plan"

    if UpgradeRequest.objects(transaction_id=transaction_id).first():
        return None, "Transaction already exists"

    try:
        user = User.objects(id=user_id).first()
    except Exception:
        return None, "User ID is invalid"
    if not user:
        return None, "User not found"

    doc = UpgradeRequest(
        transaction_id=transaction_id,
        user_id=str(user.id),
        user_email=user_email or user.email,
        requested_plan=requested_plan,
        payment_provider=payment_provider,
        amount=amount,
        currency=currency,
        note=note,
        payment_status="pending" if payment_provider == "vnpay" else "created",
        updated_at=datetime.utcnow(),
    )
    doc.save()
    return doc, None


def _emit_upgrade_code(doc: UpgradeRequest) -> None:
    if not doc.issued_code:
        return

    create_user_notification(
        user_id=doc.user_id,
        title="Ma nang cap da san sang",
        body=f"Admin da gui ma nang cap {doc.requested_plan}: {doc.issued_code}",
        notification_type="plan_upgrade_code",
        payload={
            "transaction_id": doc.transaction_id,
            "plan": doc.requested_plan,
            "code": doc.issued_code,
        },
    )

    socketio.emit(
        "plan_upgrade_code_issued",
        {
            "transaction_id": doc.transaction_id,
            "plan": doc.requested_plan,
            "code": doc.issued_code,
            "user_id": doc.user_id,
            "user_email": doc.user_email,
        },
        room=doc.user_id,
    )


def issue_upgrade_code_to_user(
    request_id: str,
    *,
    approved_by: str = "admin",
) -> Tuple[Optional[UpgradeRequest], Optional[str]]:
    try:
        doc = UpgradeRequest.objects(id=request_id).first()
    except Exception:
        return None, "Upgrade request ID is invalid"
    if not doc:
        return None, "Upgrade request not found"

    if doc.status not in ("pending", "failed", "revoked"):
        return None, "Upgrade request already processed"
    if doc.payment_provider == "vnpay" and doc.payment_status != "paid":
        return None, "Payment has not been confirmed yet"

    codes = create_upgrade_codes(doc.requested_plan, 1)
    issued_code = codes[0].code

    doc.issued_code = issued_code
    doc.status = "code_sent"
    doc.approved_by = approved_by
    doc.approved_at = datetime.utcnow()
    doc.updated_at = datetime.utcnow()
    doc.save()
    _emit_upgrade_code(doc)

    return doc, None


def resend_upgrade_code(request_id: str):
    try:
        doc = UpgradeRequest.objects(id=request_id).first()
    except Exception:
        return None, "Upgrade request ID is invalid"
    if not doc:
        return None, "Upgrade request not found"
    if not doc.issued_code:
        return None, "No code has been issued yet"

    code = UpgradeCode.objects(code=doc.issued_code).first()
    if not code or not code.is_active:
        return None, "Issued code is no longer active"

    _emit_upgrade_code(doc)
    doc.updated_at = datetime.utcnow()
    doc.save()
    return doc, None


def revoke_upgrade_code(request_id: str):
    try:
        doc = UpgradeRequest.objects(id=request_id).first()
    except Exception:
        return None, "Upgrade request ID is invalid"
    if not doc:
        return None, "Upgrade request not found"
    if not doc.issued_code:
        return None, "No code has been issued yet"

    code = UpgradeCode.objects(code=doc.issued_code).first()
    if code and code.is_active:
        code.is_active = False
        code.save()

    doc.status = "revoked"
    doc.updated_at = datetime.utcnow()
    doc.save()
    return doc, None


def serialize_upgrade_request(doc: UpgradeRequest) -> dict:
    return {
        "id": str(doc.id),
        "transaction_id": doc.transaction_id,
        "user_id": doc.user_id,
        "user_email": doc.user_email,
        "requested_plan": doc.requested_plan,
        "payment_provider": doc.payment_provider,
        "payment_status": doc.payment_status,
        "status": doc.status,
        "amount": doc.amount,
        "currency": doc.currency,
        "issued_code": doc.issued_code,
        "note": doc.note,
        "vnp_response_code": doc.vnp_response_code,
        "created_at": doc.created_at.isoformat() if doc.created_at else None,
        "updated_at": doc.updated_at.isoformat() if doc.updated_at else None,
        "paid_at": doc.paid_at.isoformat() if doc.paid_at else None,
        "approved_at": doc.approved_at.isoformat() if doc.approved_at else None,
    }


def mark_request_redeemed(code_value: str, user_id: str) -> None:
    doc = UpgradeRequest.objects(issued_code=code_value, user_id=user_id).first()
    if not doc:
        return

    doc.status = "redeemed"
    doc.updated_at = datetime.utcnow()
    doc.save()
