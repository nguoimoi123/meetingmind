from ..models.folder_model import Folder
class FolderController:
    @staticmethod
    def create_folder(user_id, name):
        if not user_id or not name:
            return {"error": "User ID and folder name are required"}, 400
        folder = Folder(
            user_id=user_id,
            name=name
        )
        folder.save()
        return {"id": str(folder.id), "name": folder.name}, 201
    
    @staticmethod
    def get_folders_by_user(user_id):
        folders = Folder.objects(user_id=user_id)
        folder_list = [{"id": str(folder.id), "name": folder.name, "created_at": folder.created_at.isoformat()} for folder in folders]
        return folder_list, 200