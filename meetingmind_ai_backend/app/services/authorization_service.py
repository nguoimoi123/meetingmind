from flask import jsonify

from ..models.file_model import File
from ..models.folder_model import Folder
from ..models.meeting_model import Meeting
from ..models.reminder_model import Reminder
from ..models.studio_result_model import StudioResult
from ..models.team_member_model import TeamMember
from .auth_token_service import extract_bearer_token, verify_user_token


def get_authenticated_user_id(request):
    token = extract_bearer_token(request)
    user_id = verify_user_token(token)
    if not user_id:
        return None, (jsonify({"error": "Unauthorized"}), 401)
    return user_id, None


def require_same_user(request, candidate_user_id: str):
    user_id, error = get_authenticated_user_id(request)
    if error:
        return None, error
    if str(candidate_user_id) != str(user_id):
        return None, (jsonify({"error": "Forbidden"}), 403)
    return user_id, None


def require_meeting_owner(request, sid: str):
    user_id, error = get_authenticated_user_id(request)
    if error:
        return None, None, error

    meeting = Meeting.objects(sid=sid).first()
    if not meeting:
        return user_id, None, (jsonify({"error": "Meeting not found"}), 404)
    if str(meeting.user_id) != str(user_id):
        return user_id, None, (jsonify({"error": "Forbidden"}), 403)
    return user_id, meeting, None


def require_folder_owner(request, folder_id: str):
    user_id, error = get_authenticated_user_id(request)
    if error:
        return None, None, error

    folder = Folder.objects(id=folder_id).first()
    if not folder:
        return user_id, None, (jsonify({"error": "Folder not found"}), 404)
    if str(folder.user_id) != str(user_id):
        return user_id, None, (jsonify({"error": "Forbidden"}), 403)
    return user_id, folder, None


def require_file_owner(request, file_id: str):
    user_id, error = get_authenticated_user_id(request)
    if error:
        return None, None, error

    file = File.objects(id=file_id).first()
    if not file:
        return user_id, None, (jsonify({"error": "File not found"}), 404)
    if str(file.user_id) != str(user_id):
        return user_id, None, (jsonify({"error": "Forbidden"}), 403)
    return user_id, file, None


def require_reminder_owner(request, reminder_id: str):
    user_id, error = get_authenticated_user_id(request)
    if error:
        return None, None, error

    reminder = Reminder.objects(id=reminder_id).first()
    if not reminder:
        return user_id, None, (jsonify({"error": "Reminder not found"}), 404)
    if str(reminder.user_id) != str(user_id):
        return user_id, None, (jsonify({"error": "Forbidden"}), 403)
    return user_id, reminder, None


def require_studio_result_owner(request, result_id: str):
    user_id, error = get_authenticated_user_id(request)
    if error:
        return None, None, error

    result = StudioResult.objects(id=result_id).first()
    if not result:
        return user_id, None, (jsonify({"error": "Studio result not found"}), 404)
    if str(result.user_id) != str(user_id):
        return user_id, None, (jsonify({"error": "Forbidden"}), 403)
    return user_id, result, None


def require_team_active_member(request, team_id: str, user_id: str):
    caller_id, error = require_same_user(request, user_id)
    if error:
        return None, None, error

    membership = TeamMember.objects(
        team_id=team_id,
        user_id=caller_id,
        status="active",
    ).first()
    if not membership:
        return caller_id, None, (jsonify({"error": "Forbidden"}), 403)
    return caller_id, membership, None
