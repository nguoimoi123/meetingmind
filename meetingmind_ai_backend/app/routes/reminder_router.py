from flask import Blueprint, request, jsonify
from datetime import datetime
from ..controllers.reminder_controller import ReminderController

reminder_bp = Blueprint("reminder", __name__, url_prefix="/reminder")

'''
curl -X POST http://localhost:5001/reminder/add \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "6965304ba729391015e6d079",
    "title": "Họp team AI",
    "remind_start": "2026-01-18T14:30:00Z",
    "remind_end": "2026-01-18T16:00:00Z",
    "location": "Phòng họp A"
  }'
'''
@reminder_bp.route('/add', methods=['POST'])
def create_reminder():
    data = request.get_json()
    user_id = data.get('user_id')
    title = data.get('title')
    location = data.get('location')

    try:
        remind_start = datetime.fromisoformat(
            data.get('remind_start').replace("Z", "+00:00")
        )
        remind_end = datetime.fromisoformat(
            data.get('remind_end').replace("Z", "+00:00")
        )
    except Exception:
        return jsonify({"error": "Invalid datetime format"}), 400

    result, status_code = ReminderController.create_reminder(
        user_id=user_id,
        title=title,
        remind_start=remind_start,
        remind_end=remind_end,
        location=location
    )
    return jsonify(result), status_code

'''
curl -X GET "http://localhost:5001/reminder/day?user_id=6965304ba729391015e6d079&date=2026-01-18"
'''
@reminder_bp.route('/day', methods=['GET'])
def get_reminder_by_day():
    user_id = request.args.get('user_id')
    date_str = request.args.get('date')

    if not user_id or not date_str:
        return {"error": "user_id and date are required"}, 400

    try:
        date = datetime.strptime(date_str, "%Y-%m-%d").date()
    except ValueError:
        return {"error": "Invalid date format (YYYY-MM-DD)"}, 400

    return ReminderController.get_by_day(user_id, date)

'''
curl -X DELETE http://127.0.0.1:5001/reminder/696b77589a34c81408175b1f
'''
@reminder_bp.route('/<reminder_id>', methods=['DELETE'])
def delete_reminder(reminder_id):
    result, status_code = ReminderController.delete_reminder(reminder_id)
    return jsonify(result), status_code