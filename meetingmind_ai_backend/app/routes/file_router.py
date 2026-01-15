from flask import Blueprint, request, jsonify
from ..controllers.file_controller import FileController

file_bp = Blueprint("file", __name__, url_prefix="/file")

'''
curl -X POST http://127.0.0.1:5000/file/upload \
-H "Content-Type: application/json" \
-d '{
  "user_id": "6965304ba729391015e6d079",
  "folder_id": "696530c8c738274d1d321ab6",
  "filename": "note1.md",
  "file_type": "md",
  "size": 2048
}'
'''
@file_bp.route("/upload", methods=["POST"])
def upload_file():
    data = request.get_json()
    if not data:
        return {"error": "No data provided"}, 400
    response, status = FileController.upload_file(
        user_id=data.get("user_id"),
        folder_id=data.get("folder_id"),
        filename=data.get("filename"),
        file_type=data.get("file_type"),
        size=data.get("size")
    )
    return jsonify(response), status

'''
curl http://127.0.0.1:5000/file/folder/6965381de947b96faf03a7ac
'''
@file_bp.route("/folder/<folder_id>", methods=["GET"])
def get_files_by_folder(folder_id):
    response, status = FileController.get_files_by_folder(folder_id)
    return jsonify(response), status