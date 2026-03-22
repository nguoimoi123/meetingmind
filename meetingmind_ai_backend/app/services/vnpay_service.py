import hashlib
import hmac
import random
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode

from app.config import Config
from app.models.upgrade_request_model import UpgradeRequest
from app.models.user_model import User


PLAN_PRICES = {
    "plus": 99000,
    "premium": 199000,
}


def _utc_now():
    return datetime.utcnow()


def _vnpay_now():
    vietnam_tz = timezone(timedelta(hours=7))
    return datetime.now(vietnam_tz).replace(tzinfo=None)


def _generate_txn_ref(plan: str) -> str:
    return f"MM{plan[:1].upper()}{_vnpay_now().strftime('%Y%m%d%H%M%S')}{random.randint(1000,9999)}"


def _get_client_ip(request) -> str:
    forwarded = request.headers.get("X-Forwarded-For", "")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.remote_addr or "127.0.0.1"


def _sorted_query(params: dict) -> str:
    filtered = {k: v for k, v in params.items() if v is not None and v != ""}
    return urlencode(sorted(filtered.items()))


def _sign(query_string: str) -> str:
    secret = (Config.VNPAY_HASH_SECRET or "").encode("utf-8")
    return hmac.new(secret, query_string.encode("utf-8"), hashlib.sha512).hexdigest()


def vnpay_ready() -> bool:
    return bool(
        (Config.VNPAY_TMN_CODE or "").strip()
        and (Config.VNPAY_HASH_SECRET or "").strip()
        and (Config.VNPAY_RETURN_URL or "").strip()
    )


def create_vnpay_payment_url(request, *, user_id: str, plan: str, amount: int | None = None):
    if plan not in PLAN_PRICES:
        return None, "Invalid plan"
    if not vnpay_ready():
        return None, "VNPAY is not configured"

    user = User.objects(id=user_id).first()
    if not user:
        return None, "User not found"

    txn_ref = _generate_txn_ref(plan)
    amount_value = int(amount or PLAN_PRICES[plan])
    create_date = _vnpay_now()
    expire_date = create_date + timedelta(minutes=30)

    doc = UpgradeRequest(
        transaction_id=txn_ref,
        user_id=str(user.id),
        user_email=user.email,
        requested_plan=plan,
        payment_provider="vnpay",
        amount=amount_value,
        currency="VND",
        payment_status="pending",
        payment_ref=txn_ref,
        vnp_txn_ref=txn_ref,
        updated_at=create_date,
        note=f"VNPAY checkout for {plan}",
    )
    doc.save()

    params = {
        "vnp_Version": "2.1.0",
        "vnp_Command": "pay",
        "vnp_TmnCode": Config.VNPAY_TMN_CODE,
        "vnp_Amount": str(amount_value * 100),
        "vnp_CreateDate": create_date.strftime("%Y%m%d%H%M%S"),
        "vnp_CurrCode": "VND",
        "vnp_IpAddr": _get_client_ip(request),
        "vnp_Locale": Config.VNPAY_LOCALE or "vn",
        "vnp_OrderInfo": f"MeetingMind {plan} upgrade for {user.email}",
        "vnp_OrderType": "other",
        "vnp_ReturnUrl": Config.VNPAY_RETURN_URL,
        "vnp_TxnRef": txn_ref,
        "vnp_ExpireDate": expire_date.strftime("%Y%m%d%H%M%S"),
    }
    query_string = _sorted_query(params)
    secure_hash = _sign(query_string)
    payment_url = f"{Config.VNPAY_PAYMENT_URL}?{query_string}&vnp_SecureHash={secure_hash}"

    return {
        "transaction_id": txn_ref,
        "payment_url": payment_url,
        "amount": amount_value,
        "plan": plan,
    }, None


def verify_vnpay_response(args) -> tuple[bool, str]:
    incoming = dict(args)
    provided_hash = incoming.pop("vnp_SecureHash", "")
    incoming.pop("vnp_SecureHashType", None)
    query_string = _sorted_query(incoming)
    calculated = _sign(query_string)
    return hmac.compare_digest(calculated.lower(), provided_hash.lower()), provided_hash


def process_vnpay_result(args):
    verified, _ = verify_vnpay_response(args)
    if not verified:
        return None, "Invalid secure hash"

    txn_ref = args.get("vnp_TxnRef")
    if not txn_ref:
        return None, "Missing transaction reference"

    doc = UpgradeRequest.objects(vnp_txn_ref=txn_ref).first()
    if not doc:
        return None, "Upgrade request not found"

    response_code = args.get("vnp_ResponseCode", "")
    transaction_no = args.get("vnp_TransactionNo", "")
    amount = args.get("vnp_Amount")

    doc.vnp_response_code = response_code
    if transaction_no:
        doc.payment_ref = transaction_no
    doc.updated_at = _utc_now()

    if response_code == "00":
        doc.payment_status = "paid"
        doc.paid_at = _utc_now()
    elif response_code in {"24"}:
        doc.payment_status = "cancelled"
    else:
        doc.payment_status = "failed"
    doc.save()

    return {
        "transaction_id": doc.transaction_id,
        "plan": doc.requested_plan,
        "payment_status": doc.payment_status,
        "response_code": response_code,
        "amount": amount,
        "user_id": doc.user_id,
        "request_id": str(doc.id),
    }, None
