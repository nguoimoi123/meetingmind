from datetime import datetime
from bson import ObjectId

def user_schema_google(email, name, avatar):
    return {
        "_id": ObjectId(),
        "email": email,
        "name": name,
        "avatar": avatar,
        "provider": "google",
        "password_hash": None,
        "created_at": datetime.utcnow()
    }
