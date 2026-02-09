import cloudinary
import cloudinary.uploader
import os
from dotenv import load_dotenv
import re

load_dotenv()

cloudinary.config(
    cloud_name=os.getenv("CLOUD_NAME"),
    api_key=os.getenv("API_KEY"),
    api_secret=os.getenv("API_SECRET")
)

def upload_audio(file_path):
    result = cloudinary.uploader.upload(
        file_path,
        resource_type="video"  
    )

    os.remove(file_path)

    return result["secure_url"]

def delete_from_cloudinary(url):
    """Xóa file từ Cloudinary dựa trên URL"""
    try:
        # Extract public_id từ URL
        # URL format: https://res.cloudinary.com/cloud_name/resource_type/upload/v123456/public_id.ext
        match = re.search(r'/upload/(?:v\d+/)?([^/]+)\.[^.]+$', url)
        if match:
            public_id = match.group(1)
            
            # Xác định resource_type dựa trên URL hoặc extension
            if '/video/' in url:
                resource_type = 'video'
            elif '/image/' in url:
                resource_type = 'image'
            else:
                resource_type = 'raw'
            
            # Xóa file từ Cloudinary
            result = cloudinary.uploader.destroy(public_id, resource_type=resource_type)
            return result.get('result') == 'ok'
        
        return False
    except Exception as e:
        print(f"Error deleting from Cloudinary: {e}")
        return False