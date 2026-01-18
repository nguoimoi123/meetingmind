from flask import Blueprint, request, jsonify
from app.services.meeting_service import get_user_meetings
from app.models.meeting_model import Meeting
from app.models.chunk_model import Chunk

meeting_bp = Blueprint("meetings", __name__, url_prefix="/meetings")

@meeting_bp.route("/", methods=["GET"])
def list_meetings():
    """
    API lấy danh sách cuộc họp.
    Param: user_id (string)
    """
    user_id = request.args.get('user_id')
    
    if not user_id:
        return jsonify({"error": "Missing user_id parameter"}), 400

    try:
        meetings = get_user_meetings(user_id)
        # Convert list object sang JSON
        result = [m.to_dict() for m in meetings]
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@meeting_bp.route("/<sid>", methods=["DELETE"])
def delete_meeting(sid):
    """
    Xóa cuộc họp và toàn bộ dữ liệu liên quan (RAG chunks).
    """
    try:
        # 1. Xóa bản ghi Meeting
        meeting = Meeting.objects(sid=sid).first()
        if not meeting:
            return jsonify({"error": "Meeting not found"}), 404
        
        meeting.delete()

        # 2. Xóa các Chunks liên quan (RAG) trong bảng Chunks
        # (Trong model chunk_model ta dùng folder_id để lưu sid của meeting)
        deleted_chunks = Chunk.objects(folder_id=sid).delete()
        print(f"Deleted {deleted_chunks} chunks for meeting {sid}")

        return jsonify({"message": "Meeting deleted successfully"}), 200
    except Exception as e:
        print(f"Error deleting meeting: {e}")
        return jsonify({"error": str(e)}), 500