from ..models.user_model import User
from werkzeug.security import generate_password_hash, check_password_hash

class UserController:
    @staticmethod
    def create_user(name, email, password):
        if User.objects(name=name).first():
            return {"error": "Username already exists"}, 400
        if User.objects(email=email).first():
            return {"error": "Email already exists"}, 400
        
        hashed_password = generate_password_hash(password)

        user = User(
            name=name,
            email=email,
            password=hashed_password
        )

        user.save()
        return {"id": str(user.id), "name": user.name}, 201
    
    @staticmethod
    def get_user(user_id):
        user = User.objects(id=user_id).first()
        if not user:
            return {"error": "User not found"}, 404
        return {
            "id": str(user.id),
            "name": user.name,
            "email": user.email,
            "created_at": user.created_at.isoformat()
        }, 200

    @staticmethod
    def change_pass(user_id, old_password, new_password):
        user = User.objects(id=user_id).first()
        if not user:
            return {"error": "User not found"}, 404
        
        if not check_password_hash(user.password, old_password):
            return {"error": "Old password is incorrect"}, 400
        
        user.password = generate_password_hash(new_password)
        user.save()
        return {"message": "Password changed successfully"}, 200
    