from flask_mongoengine import MongoEngine
from datetime import datetime
from ..extensions import db

class Reminder(db.Document):
    user_id = db.StringField(required=True)

    title = db.StringField(required=True)
    
    description = db.StringField()
    
    remind_at = db.DateTimeField(required=True)
    
    created_at = db.DateTimeField(default=datetime.utcnow)
    
    done = db.BooleanField(default=False)

    meta = {'collection': 'Reminders'}
