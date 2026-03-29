from flask import Blueprint, request, jsonify
from ..services.user_service import UserController
from ..services.auth_token_service import (
    extract_bearer_token,
    issue_user_token,
    verify_user_token,
)
from ..services.authorization_service import require_same_user
from ..services.plan_service import get_plan_limits, get_user_plan, create_upgrade_codes, redeem_upgrade_code
from ..services.usage_service import get_usage
from ..services.notification_center_service import (
    delete_user_notification,
    get_user_notifications,
    mark_all_notifications_read,
)
from ..services.admin_upgrade_service import is_admin_authorized

user_bp = Blueprint("user", __name__, url_prefix="/user")

@user_bp.route("/add", methods=["POST"])
def add_user():
    data = request.get_json()
    print(data)
    if not data:
        return {"error": "No data provided"}, 400
    response, status = UserController.create_user(
        name=data["name"],
        email=data["email"],
        password=data["password"]
    )
    if status in (200, 201) and response.get("id"):
        response["access_token"] = issue_user_token(response["id"])
    return jsonify(response), status

#[POST] http://127.0.0.1:5000/user/<user_id>
@user_bp.route("/<user_id>", methods=["GET"])
def get_user(user_id):
    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    response, status = UserController.get_user(user_id)
    return jsonify(response), status


@user_bp.route("/login", methods=["POST"])
def login_user():
    data = request.get_json()
    if not data:
        return {"error": "No data provided"}, 400
    if not data.get("email") or not data.get("password"):
        return {"error": "Email and password are required"}, 400

    response, status = UserController.login(
        email=data["email"],
        password=data["password"],
    )
    if status == 200 and response.get("id"):
        response["access_token"] = issue_user_token(response["id"])
    return jsonify(response), status


@user_bp.route("/me", methods=["GET"])
def get_current_user():
    token = extract_bearer_token(request)
    user_id = verify_user_token(token)
    if not user_id:
        return {"error": "Unauthorized"}, 401

    response, status = UserController.get_user(user_id)
    if status == 200 and response.get("id"):
        response["access_token"] = token
    return jsonify(response), status


@user_bp.route("/plan/<user_id>", methods=["GET"])
def get_user_plan_info(user_id):
    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    plan = get_user_plan(user_id)
    limits = get_plan_limits(plan)
    return jsonify({"plan": plan, "limits": limits}), 200


@user_bp.route("/upgrade-code/create", methods=["POST"])
def create_upgrade_code():
    if not is_admin_authorized():
        return {"error": "Unauthorized"}, 401

    data = request.get_json() or {}
    plan = data.get("plan")
    count = int(data.get("count", 1))

    if plan not in ("plus", "premium"):
        return {"error": "Invalid plan"}, 400

    codes = create_upgrade_codes(plan, count)
    return jsonify({
        "plan": plan,
        "codes": [c.code for c in codes],
    }), 201


@user_bp.route("/upgrade", methods=["POST"])
def upgrade_plan():
    data = request.get_json() or {}
    user_id = data.get("user_id")
    code_value = data.get("code")

    if not user_id or not code_value:
        return {"error": "user_id and code are required"}, 400

    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error

    user, error = redeem_upgrade_code(user_id, code_value)
    if error:
        return {"error": error}, 400

    return jsonify({
        "message": "Plan upgraded",
        "plan": user.plan,
        "user_id": str(user.id),
    }), 200


@user_bp.route("/usage/<user_id>", methods=["GET"])
def get_user_usage(user_id):
    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    data, error = get_usage(user_id)
    if error:
        return {"error": error}, 404
    return jsonify(data), 200


@user_bp.route("/notifications/<user_id>", methods=["GET"])
def list_user_notifications(user_id):
    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    limit = int(request.args.get("limit", 50) or 50)
    return jsonify(get_user_notifications(user_id, limit=limit)), 200


@user_bp.route("/notifications/<user_id>/read-all", methods=["POST"])
def read_all_user_notifications(user_id):
    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    count = mark_all_notifications_read(user_id)
    return jsonify({"message": "Notifications marked as read", "count": count}), 200


@user_bp.route("/notifications/<user_id>/<notification_id>", methods=["DELETE"])
def delete_one_user_notification(user_id, notification_id):
    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    deleted = delete_user_notification(user_id, notification_id)
    if not deleted:
        return {"error": "Notification not found"}, 404
    return jsonify({"message": "Notification deleted"}), 200
