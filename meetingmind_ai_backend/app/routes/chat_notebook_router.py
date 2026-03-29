from flask import Blueprint, request, jsonify
from app.services.chat_notebook_service import ChatNotebookController
from app.services.authorization_service import require_folder_owner, require_same_user

chat_bp = Blueprint("chat", __name__, url_prefix="/chat")

@chat_bp.route("/notebook", methods=["POST"])
def chat_notebook():
    data = request.json or {}
    user_id = data.get("user_id")
    folder_id = data.get("folder_id")

    if not user_id or not folder_id:
        return jsonify({"error": "user_id and folder_id are required"}), 400

    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error

    _, _, folder_error = require_folder_owner(request, folder_id)
    if folder_error:
        return folder_error

    response, status = ChatNotebookController.chat_bot_notebook(
        user_id=user_id,
        folder_id=folder_id,
        question=data.get("question"),
        file_ids=data.get("file_ids"),
        top_k=data.get("top_k", 5)
    )

    return jsonify(response), status
