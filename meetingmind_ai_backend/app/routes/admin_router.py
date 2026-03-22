from flask import Blueprint, jsonify, redirect, render_template, request, session, url_for
from mongoengine.queryset.visitor import Q
from datetime import datetime

from app.config import Config
from app.models.upgrade_request_model import UpgradeRequest
from app.models.user_model import User
from app.services.admin_upgrade_service import (
    create_upgrade_request,
    is_admin_authorized,
    issue_upgrade_code_to_user,
    resend_upgrade_code,
    revoke_upgrade_code,
    serialize_upgrade_request,
    webhook_secret_matches,
)
from app.services.notification_center_service import broadcast_user_notification


admin_bp = Blueprint("admin", __name__, url_prefix="/admin")


def _unauthorized():
    if request.path.startswith("/admin/api/"):
        return jsonify({"error": "Unauthorized"}), 401
    return redirect(url_for("admin.login_page"))


def _require_admin():
    if not is_admin_authorized():
        return _unauthorized()
    return None


def _build_query():
    query = UpgradeRequest.objects

    plan = (request.args.get("plan") or "").strip()
    status = (request.args.get("status") or "").strip()
    payment_status = (request.args.get("payment_status") or "").strip()
    search = (request.args.get("search") or "").strip()

    if plan:
        query = query.filter(requested_plan=plan)
    if status:
        query = query.filter(status=status)
    if payment_status:
        query = query.filter(payment_status=payment_status)
    if search:
        query = query.filter(
            Q(transaction_id__icontains=search)
            | Q(user_id__icontains=search)
            | Q(user_email__icontains=search)
            | Q(issued_code__icontains=search)
        )

    return query.order_by("-created_at")


def _build_analytics(docs):
    now = datetime.utcnow()
    month_labels = []
    monthly = []
    for month in range(1, 13):
        label = f"{month:02d}/{now.year}"
        month_labels.append(label)
        month_docs = [
            doc for doc in docs
            if doc.created_at and doc.created_at.year == now.year and doc.created_at.month == month
        ]
        paid_docs = [
            doc for doc in docs
            if doc.paid_at and doc.paid_at.year == now.year and doc.paid_at.month == month
        ]
        monthly.append({
            "label": label,
            "requests": len(month_docs),
            "paid": len(paid_docs),
            "revenue": int(sum((doc.amount or 0) for doc in paid_docs)),
        })

    yearly_map = {}
    for doc in docs:
        if not doc.created_at:
            continue
        year = str(doc.created_at.year)
        yearly_map.setdefault(year, {"year": year, "requests": 0, "paid": 0, "revenue": 0})
        yearly_map[year]["requests"] += 1
        if doc.paid_at:
            yearly_map[year]["paid"] += 1
            yearly_map[year]["revenue"] += int(doc.amount or 0)

    yearly = [yearly_map[key] for key in sorted(yearly_map.keys())]
    return {"monthly": monthly, "yearly": yearly}


def _stats():
    docs = UpgradeRequest.objects
    return {
        "total": docs.count(),
        "paid_waiting_code": docs.filter(payment_status="paid", status="pending").count(),
        "codes_sent": docs.filter(status="code_sent").count(),
        "redeemed": docs.filter(status="redeemed").count(),
    }


@admin_bp.route("/login", methods=["GET", "POST"])
def login_page():
    error = None
    if request.method == "POST":
        key = (request.form.get("admin_key") or "").strip()
        configured = (Config.ADMIN_DASHBOARD_KEY or "").strip()
        if configured and key == configured:
            session["admin_logged_in"] = True
            return redirect(url_for("admin.admin_console"))
        error = "Admin key khong dung"

    return render_template("admin_login.html", error=error)


@admin_bp.route("/api/auth/login", methods=["POST"])
def login_api():
    data = request.get_json() or {}
    key = (data.get("admin_key") or "").strip()
    configured = (Config.ADMIN_DASHBOARD_KEY or "").strip()
    if not configured or key != configured:
        return jsonify({"error": "Admin key khong dung"}), 401

    session["admin_logged_in"] = True
    return jsonify({"message": "Login success"}), 200


@admin_bp.route("/api/auth/me", methods=["GET"])
def auth_me():
    if not is_admin_authorized():
        return jsonify({"authenticated": False}), 401
    return jsonify({"authenticated": True}), 200


@admin_bp.route("/logout", methods=["POST"])
def logout():
    session.pop("admin_logged_in", None)
    return redirect(url_for("admin.login_page"))


@admin_bp.route("/api/auth/logout", methods=["POST"])
def logout_api():
    session.pop("admin_logged_in", None)
    return jsonify({"message": "Logout success"}), 200


@admin_bp.route("", methods=["GET"])
def admin_console():
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    return render_template("admin_console.html", stats=_stats())


@admin_bp.route("/api/payments/webhook", methods=["POST"])
def payment_webhook():
    if not webhook_secret_matches():
        return jsonify({"error": "Invalid webhook secret"}), 401

    data = request.get_json() or {}
    doc, error = create_upgrade_request(
        transaction_id=(data.get("transaction_id") or "").strip(),
        user_id=(data.get("user_id") or "").strip(),
        requested_plan=(data.get("requested_plan") or "").strip(),
        user_email=data.get("user_email"),
        payment_provider=(data.get("payment_provider") or "payment-webhook").strip(),
        amount=data.get("amount"),
        currency=(data.get("currency") or "VND").strip(),
        note=data.get("note"),
    )
    if error:
        return jsonify({"error": error}), 400

    return jsonify({"message": "Webhook received", "request": serialize_upgrade_request(doc)}), 201


@admin_bp.route("/api/upgrade-requests/mock", methods=["POST"])
def create_mock_request():
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    data = request.get_json() or {}
    doc, error = create_upgrade_request(
        transaction_id=(data.get("transaction_id") or "").strip(),
        user_id=(data.get("user_id") or "").strip(),
        requested_plan=(data.get("requested_plan") or "").strip(),
        user_email=data.get("user_email"),
        payment_provider=(data.get("payment_provider") or "manual").strip(),
        amount=data.get("amount"),
        currency=(data.get("currency") or "VND").strip(),
        note=data.get("note"),
    )
    if error:
        return jsonify({"error": error}), 400

    return jsonify({"request": serialize_upgrade_request(doc)}), 201


@admin_bp.route("/api/upgrade-requests", methods=["GET"])
def list_upgrade_requests():
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    page = max(int(request.args.get("page", 1) or 1), 1)
    page_size = min(max(int(request.args.get("page_size", 20) or 20), 1), 100)
    query = _build_query()
    total = query.count()
    start = (page - 1) * page_size
    docs = query.skip(start).limit(page_size)
    return jsonify({
        "stats": _stats(),
        "page": page,
        "page_size": page_size,
        "total": total,
        "total_pages": max((total + page_size - 1) // page_size, 1),
        "requests": [serialize_upgrade_request(doc) for doc in docs[:100]],
    }), 200


@admin_bp.route("/api/analytics/upgrade-requests", methods=["GET"])
def upgrade_request_analytics():
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    docs = list(UpgradeRequest.objects.order_by("created_at"))
    return jsonify({
        "stats": _stats(),
        "analytics": _build_analytics(docs),
    }), 200


@admin_bp.route("/api/users/search", methods=["GET"])
def search_users():
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    query = (request.args.get("q") or "").strip()
    if not query:
        return jsonify({"users": []}), 200

    lowered = query.lower()
    docs = []
    for doc in User.objects[:200]:
        haystacks = [str(doc.id).lower(), (doc.email or "").lower(), (doc.name or "").lower()]
        if any(lowered in value for value in haystacks):
            docs.append(doc)
        if len(docs) >= 12:
            break

    return jsonify(
        {
            "users": [
                {
                    "id": str(doc.id),
                    "email": doc.email,
                    "name": doc.name,
                    "plan": doc.plan,
                }
                for doc in docs
            ]
        }
    ), 200


@admin_bp.route("/api/notifications/broadcast", methods=["POST"])
def broadcast_notification():
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    data = request.get_json() or {}
    title = (data.get("title") or "").strip()
    body = (data.get("body") or "").strip()
    notification_type = (data.get("type") or "system").strip() or "system"
    target_plan = (data.get("target_plan") or "").strip()

    if not title:
        return jsonify({"error": "Title is required"}), 400
    if not body:
        return jsonify({"error": "Body is required"}), 400

    if target_plan not in {"", "free", "plus", "premium"}:
        return jsonify({"error": "Invalid target plan"}), 400

    sent = broadcast_user_notification(
        title=title,
        body=body,
        notification_type=notification_type,
        payload={
            "source": "admin_broadcast",
            "target_plan": target_plan or "all",
        },
        target_plan=target_plan or None,
    )

    return jsonify(
        {
            "message": "Broadcast sent",
            "sent_count": sent,
            "target_plan": target_plan or "all",
        }
    ), 200


@admin_bp.route("/api/upgrade-requests/<request_id>/issue-code", methods=["POST"])
def issue_code(request_id):
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    data = request.get_json() or {}
    doc, error = issue_upgrade_code_to_user(
        request_id,
        approved_by=(data.get("approved_by") or "admin").strip(),
    )
    if error:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Code sent", "request": serialize_upgrade_request(doc)}), 200


@admin_bp.route("/api/upgrade-requests/<request_id>/resend-code", methods=["POST"])
def resend_code(request_id):
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    doc, error = resend_upgrade_code(request_id)
    if error:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Code resent", "request": serialize_upgrade_request(doc)}), 200


@admin_bp.route("/api/upgrade-requests/<request_id>/revoke-code", methods=["POST"])
def revoke_code(request_id):
    unauthorized = _require_admin()
    if unauthorized:
        return unauthorized

    doc, error = revoke_upgrade_code(request_id)
    if error:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Code revoked", "request": serialize_upgrade_request(doc)}), 200
