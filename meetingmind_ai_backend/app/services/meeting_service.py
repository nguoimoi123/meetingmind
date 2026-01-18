from datetime import datetime
from app.models.chunk_model import Chunk

from ..models.meeting_model import Meeting

def get_or_create_meeting(sid, user_id):
    """
    Lấy cuộc họp nếu đã có, nếu chưa thì tạo mới.
    Được gọi ngay khi bắt đầu Socket kết nối.
    """
    meeting = Meeting.objects(sid=sid).first()
    if not meeting:
        meeting = Meeting(
            sid=sid,
            user_id=user_id,
            status="in_progress"
        )
        meeting.save()
    return meeting

def append_transcript(sid, text):
    """
    Nối thêm câu mới vào full_transcript của cuộc họp.
    Gọi khi có kết quả chép lời hoàn chỉnh.
    """
    meeting = Meeting.objects(sid=sid).first()
    if meeting:
        if meeting.full_transcript:
            meeting.full_transcript += "\n" + text
        else:
            meeting.full_transcript = text
        meeting.save()

def save_summary(sid, summary_data):
    """
    Lưu kết quả tóm tắt sau khi họp xong.
    Cập nhật status thành 'completed'.
    """
    meeting = Meeting.objects(sid=sid).first()
    if meeting:
        meeting.status = "completed"
        meeting.ended_at = datetime.utcnow()
        meeting.summary = summary_data.get("summary")
        meeting.action_items = summary_data.get("action_items", [])
        meeting.key_decisions = summary_data.get("key_decisions", [])
        
        # Nếu chưa có transcript (do lỗi gì đó), lấy từ data trả về
        if not meeting.full_transcript:
            meeting.full_transcript = summary_data.get("full_transcript")
            
        meeting.save()
    return meeting

def get_user_meetings(user_id):
    """
    Lấy danh sách cuộc họp của 1 user, sắp xếp theo thời gian mới nhất.
    """
    return Meeting.objects(user_id=user_id).order_by('-created_at')
def delete_meeting_by_sid(sid):
    meeting = Meeting.objects(sid=sid).first()
    if not meeting:
        return False

    meeting.delete()
    Chunk.objects(folder_id=sid).delete()
    return True