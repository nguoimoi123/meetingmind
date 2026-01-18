from ..models.reminder_model import Reminder
from datetime import datetime, time

class ReminderController:
    @staticmethod
    def create_reminder(user_id, title, remind_start, remind_end, location=None):
        reminder = Reminder(
            user_id=user_id,
            title=title,
            remind_start=remind_start,
            remind_end=remind_end,
            location=location
        )
        reminder.save()
        return {"id": str(reminder.id), "title": reminder.title}, 201
    
    @staticmethod
    def get_by_day(user_id, date):
        start_of_day = datetime.combine(date, time.min)
        end_of_day   = datetime.combine(date, time.max)

        reminders = Reminder.objects(
            user_id=user_id,
            remind_start__gte=start_of_day,
            remind_start__lte=end_of_day
        ).order_by('remind_start')

        return [
            {
                "id": str(r.id),
                "title": r.title,
                "remind_start": r.remind_start.isoformat(),
                "remind_end": r.remind_end.isoformat(),
                "location": r.location,
                "done": r.done
            }
            for r in reminders
        ], 200

    @staticmethod
    def delete_reminder(reminder_id):
        reminder = Reminder.objects(id=reminder_id).first()
        if not reminder:
            return {"error": "Reminder not found"}, 404
        reminder.delete()
        return {"message": "Reminder deleted"}, 200