from flask import Blueprint, jsonify, request
from openai import OpenAI

from app.config import Config
from app.services.authorization_service import require_meeting_owner, require_same_user
from app.services.rag_service import retrieve_relevant_chunks

bp = Blueprint("chatm", __name__, url_prefix="/chat")
client = OpenAI(api_key=Config.OPENAI_API_KEY)


@bp.route("/meeting", methods=["POST"])
def chat_with_meeting():
    data = request.get_json() or {}
    query = data.get("query")
    sid = data.get("sid")
    user_id = data.get("user_id", "default_user")

    if not query or not sid:
        return jsonify({"error": "Missing query or sid"}), 400

    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error

    _, meeting, meeting_error = require_meeting_owner(request, sid)
    if meeting_error:
        return meeting_error

    relevant_chunks = retrieve_relevant_chunks(user_id, query, top_k=3, folder_id=sid)

    context_text = ""
    source_type = "RAG"

    if not relevant_chunks:
        if meeting and meeting.full_transcript:
            raw_transcript = meeting.full_transcript
            if len(raw_transcript) > 4000:
                raw_transcript = raw_transcript[:4000] + "..."

            context_text = (
                "Day la noi dung cuoc hop chua duoc index day du:\n"
                f"{raw_transcript}"
            )
            source_type = "RAW_TRANSCRIPT"
        else:
            context_text = "Khong tim thay thong tin ve cuoc hop nay."
            source_type = "NONE"
    else:
        context_text = "\n".join([chunk.text for chunk in relevant_chunks])

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "Ban la tro ly huu ich, tra loi ngan gon suc tich.",
                },
                {"role": "user", "content": f"""
    Ban la tro ly hop thong minh cua MeetingMind.

    Du lieu nguon: {source_type}

    --- CONTEXT ---
    {context_text}
    --- END CONTEXT ---

    Nhiem vu: Tra loi cau hoi cua nguoi dung dua tren CONTEXT tren.
    Cau hoi: {query}

    Neu trong context khong co thong tin, hay tra loi:
    "Xin loi, toi khong tim thay thong tin nay trong noi dung cuoc hop."
    """},
            ],
            temperature=0.5,
        )
        answer = response.choices[0].message.content.strip()
        return jsonify({"answer": answer, "source": source_type})
    except Exception as e:
        print(f"Chat error: {e}")
        return jsonify({"error": str(e)}), 500
