from flask import Flask
from .config import Config
from .extensions import db
from .auth.google import auth_bp
from app.extensions import socketio
from app.routes.summarize_routes import bp
from .routes.user_router import user_bp
from .routes.folder_router import folder_bp
from .routes.file_router import file_bp
from .routes.chunk_router import chunk_bp
from .routes.chat_notebook_router import chat_bp
import app.sockets.meeting_socket
def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)  # init MongoEngine
    socketio.init_app(app)
    app.register_blueprint(bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(user_bp)
    app.register_blueprint(folder_bp)
    app.register_blueprint(file_bp)
    app.register_blueprint(chunk_bp)
    app.register_blueprint(chat_bp)

    return app
