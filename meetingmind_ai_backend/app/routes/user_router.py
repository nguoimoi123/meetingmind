from flask import Blueprint, request, jsonify
from ..controllers.user_controller import UserController

user_bp = Blueprint("user", __name__, url_prefix="/user")

'''
curl -X POST http://127.0.0.1:5000/user/add \
-H "Content-Type: application/json" \
-d '{"email":"phuc@example.com","name":"phuc","password":"123"}
'''
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

