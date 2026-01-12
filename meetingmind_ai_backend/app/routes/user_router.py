from flask import Blueprint, request, jsonify
from ..controllers.user_controller import UserController

user_bp = Blueprint("user", __name__, url_prefix="/user")

@user_bp.route("/add", methods=["POST"])
def add_user():
    data = request.get_json()
    if not data:
        return {"error": "No data provided"}, 400
    return UserController.create_user(
        username=data["username"],
        email=data["email"],
        password=data["password"]
    )
