from datetime import datetime
from ..extensions import db

class StudioResult(db.Document):
    """Model cho kết quả đã tạo từ Studio features"""
    
    user_id = db.StringField(required=True)
    folder_id = db.StringField(required=True)
    
    # Loại tính năng: audio_summary, mindmap, quick_summary, flashcards
    type = db.StringField(required=True, choices=[
        'audio_summary',
        'mindmap', 
        'quick_summary',
        'flashcards'
    ])
    
    name = db.StringField(required=True)
    
    # URL của file kết quả (audio, image, pdf từ Cloudinary)
    url = db.StringField(required=True)
    
    # URL thumbnail nếu có
    thumbnail_url = db.StringField()
    
    # Kích thước file (bytes)
    size = db.IntField()
    
    # Metadata bổ sung (ví dụ: duration cho audio, số trang cho pdf, etc.)
    metadata = db.DictField()
    
    created_at = db.DateTimeField(default=datetime.utcnow)
    
    meta = {
        'collection': 'StudioResults',
        'indexes': [
            'user_id',
            'folder_id',
            'type',
            '-created_at',  # Sắp xếp giảm dần theo thời gian tạo
        ],
    }
