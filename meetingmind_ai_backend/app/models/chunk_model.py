from datetime import datetime
from bson import ObjectId

def chunk_schema(user_id, folder_id, file_id, index, text, embedding):
    return {
        "_id": ObjectId(),
        "user_id": ObjectId(user_id),
        "folder_id": ObjectId(folder_id),
        "file_id": ObjectId(file_id),
        "chunk_index": index,
        "text": text,
        "embedding": embedding,  # list[float]
        "created_at": datetime.utcnow()
    }
