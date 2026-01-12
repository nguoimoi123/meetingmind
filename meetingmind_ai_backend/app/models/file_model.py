from flask_mongoengine import MongoEngine
from datetime import datetime
from ..extensions import db

class File(db.Document):
    user_id = db.StringField(required=True)

    folder_id = db.StringField(required=True)

    filename = db.StringField(required=True)

    file_type = db.StringField(required=True)

    size = db.IntField(required=True)

    uploaded_at = db.DateTimeField(default=datetime.utcnow)
    
    meta = {'collection': 'Files'}
