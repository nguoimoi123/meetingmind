from flask import Blueprint, request, jsonify
from app.services.chunk_service import ChunkController
from app.services.authorization_service import require_folder_owner, require_same_user

chunk_bp = Blueprint("chunk", __name__, url_prefix="/chunks")

@chunk_bp.route("", methods=["POST"])
def create_chunk():
    data = request.get_json()
    if not data:
        return {"error": "No data provided"}, 400
    _, auth_error = require_same_user(request, data.get("user_id"))
    if auth_error:
        return auth_error
    _, _, folder_error = require_folder_owner(request, data.get("folder_id"))
    if folder_error:
        return folder_error

    response, status = ChunkController.create_chunk(data.get("user_id"),
                                                    data.get("folder_id"),
                                                    data.get("file_id"),
                                                    data.get("chunk_index"),
                                                    data.get("text"),
                                                    data.get("embedding"))
    return jsonify(response), status

@chunk_bp.route("/folder/<folder_id>", methods=["GET"])
def get_chunks_by_folder(folder_id):
    _, _, auth_error = require_folder_owner(request, folder_id)
    if auth_error:
        return auth_error
    response, status = ChunkController.get_chunks_by_folder(folder_id)
    return jsonify(response), status
