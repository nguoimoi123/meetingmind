from flask import Blueprint, request, jsonify
from ..controllers.chunk_controller import ChunkController

chunk_bp = Blueprint("chunk", __name__, url_prefix="/chunk")

'''
curl -X POST http://127.0.0.1:5000/chunk/create \
-H "Content-Type: application/json" \
-d '{
  "user_id": "6965304ba729391015e6d079",
  "folder_id": "696530c8c738274d1d321ab6",
  "file_id": "6965381de947b96faf03a7ac",
  "chunk_index": 0,
  "text": "This is the first chunk",
  "embedding": [0.01, 0.23, 0.45]
}'
'''
@chunk_bp.route("/create", methods=["POST"])
def create_chunk():
    data = request.get_json()
    if not data:
        return {"error": "No data provided"}, 400

    response, status = ChunkController.create_chunk(data.get("user_id"),
                                                    data.get("folder_id"),
                                                    data.get("file_id"),
                                                    data.get("chunk_index"),
                                                    data.get("text"),
                                                    data.get("embedding"))
    return jsonify(response), status