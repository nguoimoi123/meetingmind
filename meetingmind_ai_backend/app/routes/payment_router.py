from flask import Blueprint, jsonify, request

from app.services.authorization_service import require_same_user
from app.services.vnpay_service import create_vnpay_payment_url, process_vnpay_result


payment_bp = Blueprint("payment", __name__, url_prefix="/payments")


@payment_bp.route("/vnpay/create", methods=["POST"])
def create_vnpay_payment():
    data = request.get_json() or {}
    user_id = (data.get("user_id") or "").strip()
    plan = (data.get("plan") or "").strip()
    amount = data.get("amount")

    if not user_id or not plan:
        return jsonify({"error": "user_id and plan are required"}), 400

    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error

    result, error = create_vnpay_payment_url(
        request,
        user_id=user_id,
        plan=plan,
        amount=amount,
    )
    if error:
        return jsonify({"error": error}), 400
    return jsonify(result), 201


@payment_bp.route("/vnpay/return", methods=["GET"])
def vnpay_return():
    result, error = process_vnpay_result(request.args)
    if error:
        return f"""
        <html><body style="font-family:Arial;padding:32px;">
        <h2>Payment verification failed</h2>
        <p>{error}</p>
        </body></html>
        """, 400

    status_text = "Thanh toan thanh cong" if result["payment_status"] == "paid" else "Thanh toan chua hoan tat"
    return f"""
    <html>
      <body style="font-family:Arial;background:#f4f7fb;padding:32px;color:#122033;">
        <div style="max-width:560px;margin:0 auto;background:white;border-radius:20px;padding:28px;box-shadow:0 20px 50px rgba(17,24,39,.08);">
          <h1 style="margin-top:0;">MeetingMind Payment Result</h1>
          <p style="font-size:18px;font-weight:700;">{status_text}</p>
          <p>Goi: <strong>{result["plan"]}</strong></p>
          <p>Transaction: <strong>{result["transaction_id"]}</strong></p>
          <p>Response code: <strong>{result["response_code"]}</strong></p>
          <p>Neu thanh toan thanh cong, admin se duyet va gui code kich hoat den app cua ban.</p>
        </div>
      </body>
    </html>
    """, 200


@payment_bp.route("/vnpay/ipn", methods=["GET"])
def vnpay_ipn():
    result, error = process_vnpay_result(request.args)
    if error:
        return jsonify({"RspCode": "97", "Message": error}), 400

    return jsonify({"RspCode": "00", "Message": "Confirm Success", "data": result}), 200
