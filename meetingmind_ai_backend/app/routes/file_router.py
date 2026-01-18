from flask import Blueprint, request, jsonify
<<<<<<< HEAD
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
=======
from app.services.file_service import FileController

file_bp = Blueprint("file", __name__, url_prefix="/file")

>>>>>>> origin/quan
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
        size=data.get("size"),
        content=data.get("content")
    )
    return jsonify(response), status

<<<<<<< HEAD
'''
curl http://127.0.0.1:5000/file/folder/6965381de947b96faf03a7ac
'''
=======
>>>>>>> origin/quan
@file_bp.route("/folder/<folder_id>", methods=["GET"])
def get_files_by_folder(folder_id):
    response, status = FileController.get_files_by_folder(folder_id)
    return jsonify(response), status

<<<<<<< HEAD
'''
curl -X DELETE http://localhost:5001/file/delete/696836ce8af4b7f01b3facb9
'''
=======
>>>>>>> origin/quan

@file_bp.route("/delete/<file_id>", methods=["DELETE"])
def delete_file(file_id):
    response, status = FileController.delete_file(file_id)
    return jsonify(response), status