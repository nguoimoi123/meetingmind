from flask import Flask
from .config import Config
from .extensions import db
from .auth.google import auth_bp

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)  # init MongoEngine

    app.register_blueprint(auth_bp)

    return app
