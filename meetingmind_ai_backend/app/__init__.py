from flask import Flask
from flask import request, jsonify
from .config import Config
from .extensions import db

from .models.user_model import User

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)

    @app.route("/")
    def index():
        return {"status": "OK"}
    
    @app.route("/add", methods=["POST"])
    def add():
        data = request.get_json()
        if not data:
            return {"error": "No data provided"}, 400

        try:
            user = User(
                email=data.get("email"),
                name=data.get("name"),
                password=data.get("password")
            )
            user.save()
            return jsonify({
                "id": str(user.id),
                "name": user.name,
                "email": user.email
            }), 201

        except NotUniqueError:
            return {"error": f"Email {data.get('email')} already exists"}, 409  # 409 Conflict
        except Exception as e:
            return {"error": str(e)}, 500
    
    @app.route("/all", methods=["GET"])
    def all():
        users = User.objects()
        return jsonify([{"id": str(user.id), "name": user.name, "email": user.email, "password": user.password} for user in users])

    return app
