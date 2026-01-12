from datetime import datetime
from bson import ObjectId

def folder_schema(user_id, name):
    return {
        "_id": ObjectId(),
        "user_id": ObjectId(user_id),
        "name": name,
        "created_at": datetime.utcnow()
    }
