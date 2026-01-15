from flask import Blueprint, request, jsonify
from ..controllers.folder_controller import FolderController

folder_bp = Blueprint("folder", __name__, url_prefix="/folder")

'''
curl -X POST http://127.0.0.1:5000/folder/add \
-H "Content-Type: application/json" \
-d '{
  "user_id": "6965304ba729391015e6d079",
  "name": "My First Folder",
"description": "This is a sample folder"
}'
'''
@folder_bp.route("/add", methods=["POST"])
def add_folder():
    data = request.get_json()
    if not data:
        return {"error": "No data provided"}, 400
    response, status = FolderController.create_folder(
        user_id=data["user_id"],
        name=data["name"],
        description=data["description"],
    )
    return jsonify(response), status

'''
curl http://127.0.0.1:5000/folder/6965304ba729391015e6d079
'''
@folder_bp.route("/<user_id>", methods=["GET"])
def get_folders(user_id):
    response, status = FolderController.get_folders_by_user(user_id)
    return jsonify(response), status
