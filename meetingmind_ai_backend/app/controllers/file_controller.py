from ..models.file_model import File
from ..models.folder_model import Folder

class FileController:
    @staticmethod
    def upload_file(user_id, folder_id, filename, file_type, size):
        if not all([user_id, folder_id, filename, file_type, size]):
            return {"error": "All file details are required"}, 400
        file = File(
            user_id=user_id,
            folder_id=folder_id,
            filename=filename,
            file_type=file_type,
            size=size
        )
        file.save()
        return {"id": str(file.id), "filename": file.filename}, 201
    
    @staticmethod
    def get_files_by_folder(folder_id):
        try:
            folder = Folder.objects.get(id=folder_id)
        except Folder.DoesNotExist:
            return {"error": "Folder not found"}, 404
        files = File.objects(folder_id=folder_id)

        file_list = [{"id": str(file.id), "filename": file.filename, "file_type": file.file_type, "size": file.size, "uploaded_at": file.uploaded_at.isoformat()} for file in files]
        return {
            "folder_name": folder.name,
            "files": file_list}, 200
    
    @staticmethod
    def delete_file(file_id):
        try:
            file = File.objects.get(id=file_id)
        except File.DoesNotExist:
            return {"error": "File not found"}, 404
        file.delete()
        return {"message": "File deleted successfully"}, 200
    