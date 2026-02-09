from ..models.studio_result_model import StudioResult
from datetime import datetime
from .studio_service.cloudinary_service import delete_from_cloudinary

class StudioResultController:
    
    @staticmethod
    def create_result(user_id, folder_id, result_type, name, url, thumbnail_url=None, size=None, metadata=None):
        """Tạo studio result mới"""
        try:
            result = StudioResult(
                user_id=user_id,
                folder_id=folder_id,
                type=result_type,
                name=name,
                url=url,
                thumbnail_url=thumbnail_url,
                size=size,
                metadata=metadata or {}
            )
            result.save()
            
            return {
                "id": str(result.id),
                "user_id": result.user_id,
                "folder_id": result.folder_id,
                "type": result.type,
                "name": result.name,
                "url": result.url,
                "thumbnail_url": result.thumbnail_url,
                "size": result.size,
                "metadata": result.metadata,
                "created_at": result.created_at.isoformat()
            }, 201
        except Exception as e:
            return {"error": str(e)}, 500
    
    @staticmethod
    def get_results_by_folder(folder_id):
        """Lấy tất cả studio results của một folder"""
        try:
            results = StudioResult.objects(folder_id=folder_id).order_by('-created_at')
            
            result_list = []
            for result in results:
                result_list.append({
                    "id": str(result.id),
                    "user_id": result.user_id,
                    "folder_id": result.folder_id,
                    "type": result.type,
                    "name": result.name,
                    "url": result.url,
                    "thumbnail_url": result.thumbnail_url,
                    "size": result.size,
                    "metadata": result.metadata,
                    "created_at": result.created_at.isoformat()
                })
            
            return {"results": result_list}, 200
        except Exception as e:
            return {"error": str(e)}, 500
    
    @staticmethod
    def get_results_by_user(user_id):
        """Lấy tất cả studio results của một user"""
        try:
            results = StudioResult.objects(user_id=user_id).order_by('-created_at')
            
            result_list = []
            for result in results:
                result_list.append({
                    "id": str(result.id),
                    "user_id": result.user_id,
                    "folder_id": result.folder_id,
                    "type": result.type,
                    "name": result.name,
                    "url": result.url,
                    "thumbnail_url": result.thumbnail_url,
                    "size": result.size,
                    "metadata": result.metadata,
                    "created_at": result.created_at.isoformat()
                })
            
            return {"results": result_list}, 200
        except Exception as e:
            return {"error": str(e)}, 500
    
    @staticmethod
    def get_result_by_id(result_id):
        """Lấy một studio result theo ID"""
        try:
            result = StudioResult.objects.get(id=result_id)
            
            return {
                "id": str(result.id),
                "user_id": result.user_id,
                "folder_id": result.folder_id,
                "type": result.type,
                "name": result.name,
                "url": result.url,
                "thumbnail_url": result.thumbnail_url,
                "size": result.size,
                "metadata": result.metadata,
                "created_at": result.created_at.isoformat()
            }, 200
        except StudioResult.DoesNotExist:
            return {"error": "Studio result not found"}, 404
        except Exception as e:
            return {"error": str(e)}, 500
    
    @staticmethod
    def delete_result(result_id):
        """Xóa studio result và file trên Cloudinary"""
        try:
            result = StudioResult.objects.get(id=result_id)
            
            # Xóa file từ Cloudinary nếu có URL
            if result.url:
                delete_from_cloudinary(result.url)
            
            # Xóa thumbnail nếu có
            if result.thumbnail_url:
                delete_from_cloudinary(result.thumbnail_url)
            
            # Xóa record từ database
            result.delete()
            
            return {"message": "Studio result deleted successfully"}, 200
        except StudioResult.DoesNotExist:
            return {"error": "Studio result not found"}, 404
        except Exception as e:
            return {"error": str(e)}, 500
