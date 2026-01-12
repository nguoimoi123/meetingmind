from datetime import datetime
from bson import ObjectId

def file_schema(user_id, folder_id, filename, file_type, size):
    return {
        "_id": ObjectId(),
        "user_id": ObjectId(user_id),
        "folder_id": ObjectId(folder_id),
        "filename": filename,
        "file_type": file_type,
        "size": size,
        "uploaded_at": datetime.utcnow()
    }
