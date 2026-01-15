from flask import Blueprint, request, jsonify
from ..controllers.chat_notebook_controller import ChatNotebookController

chat_bp = Blueprint("chat", __name__, url_prefix="/chat")

'''
curl -X POST http://localhost:5001/chat/notebook \
-H "Content-Type: application/json" \
-d '{
  "user_id": "6965304ba729391015e6d079",
  "folder_id": "69660691dfa670575976fc4c",
  "question": "Giải thích lại nội dung chính của tài liệu"
}'
'''
@chat_bp.route("/notebook", methods=["POST"])
def chat_notebook():
    data = request.json

    response, status = ChatNotebookController.chat_bot_notebook(
        user_id=data.get("user_id"),
        folder_id=data.get("folder_id"),
        question=data.get("question"),
        top_k=data.get("top_k", 5)
    )

    return jsonify(response), status
