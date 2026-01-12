from flask_mongoengine import MongoEngine
from datetime import datetime
from ..extensions import db

class User(db.Document):
    email = db.StringField(required=True, unique=True)

    name = db.StringField(required=True)

    password = db.StringField(required=True)

    created_at = db.DateTimeField(default=datetime.utcnow)

    meta = {'collection': 'Users'}

