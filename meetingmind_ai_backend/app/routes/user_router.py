from flask import Blueprint, request, jsonify
from ..services.user_service import UserController

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
    return jsonify(response), status

#[POST] http://127.0.0.1:5000/user/<user_id>
@user_bp.route("/<user_id>", methods=["GET"])
def get_user(user_id):
    response, status = UserController.get_user(user_id)
    return jsonify(response), status


@user_bp.route("/change_password", methods=["POST"])
def change_password():
    data = request.get_json()
    if not data:
        return {"error": "No data provided"}, 400
    response, status = UserController.change_pass(
        user_id=data["user_id"],
        old_password=data["old_password"],
        new_password=data["new_password"]
    )
    return jsonify(response), status
