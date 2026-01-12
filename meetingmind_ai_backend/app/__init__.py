from flask import Flask
from .config import Config
from .extensions import db

from .routes.user_router import user_bp
from .routes.folder_router import folder_bp
from .routes.file_router import file_bp
from .routes.chunk_router import chunk_bp

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)

    app.register_blueprint(user_bp)
    app.register_blueprint(folder_bp)
    app.register_blueprint(file_bp)
    app.register_blueprint(chunk_bp)

    return app
