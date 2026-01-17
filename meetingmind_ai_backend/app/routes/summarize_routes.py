from flask import Blueprint, jsonify, request
from app.services.openai_service import summarize_transcript
from app.services.speechmatics_service import session_transcripts

bp = Blueprint("summarize", __name__)

@bp.route("/summarize/<sid>", methods=["GET"])
def summarize_sid(sid):
    transcript = "\n".join(session_transcripts.get(sid, []))
    if not transcript:
        return jsonify({"error": "No transcript"}), 400

    data = summarize_transcript(transcript)
    return jsonify({
        "summary": data.get("summary", ""),
        "action_items": data.get("action_items", []),
        "key_decisions": data.get("key_decisions", []),
        "full_transcript": transcript
    })

@bp.route("/summarize", methods=["POST"])
def summarize_post():
    body = request.get_json()
    transcript = body.get("transcript", "").strip()
    if not transcript:
        return jsonify({"error": "No transcript"}), 400

    data = summarize_transcript(transcript)
    return jsonify({
        "summary": data.get("summary", ""),
        "action_items": data.get("action_items", []),
        "key_decisions": data.get("key_decisions", []),
        "full_transcript": transcript
    })
