from flask import Blueprint, request, jsonify
from app.services.folder_service import FolderController
from app.services.authorization_service import require_folder_owner, require_same_user

folder_bp = Blueprint("folder", __name__, url_prefix="/folder")


@folder_bp.route("/add", methods=["POST"])
def add_folder():
    data = request.get_json()
    if not data:
        return {"error": "No data provided"}, 400
    _, auth_error = require_same_user(request, data["user_id"])
    if auth_error:
        return auth_error
    response, status = FolderController.create_folder(
        user_id=data["user_id"],
        name=data["name"],
        description=data["description"],
    )
    return jsonify(response), status

@folder_bp.route("/<user_id>", methods=["GET"])
def get_folders(user_id):
    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    response, status = FolderController.get_folders_by_user(user_id)
    return jsonify(response), status
@folder_bp.route("/delete/<folder_id>", methods=["DELETE"])
def delete_folder(folder_id):
    _, _, auth_error = require_folder_owner(request, folder_id)
    if auth_error:
        return auth_error
    response, status = FolderController.delete_folder(folder_id)
    return jsonify(response), status
