from flask import Flask
from .config import Config
from .extensions import db, socketio
from .auth.google import auth_bp
from .routes.summarize_routes import bp
from .routes.user_router import user_bp
from .routes.folder_router import folder_bp
from .routes.file_router import file_bp
from .routes.chunk_router import chunk_bp
from .routes.chat_notebook_router import chat_bp
from .routes.meeting_routes import meeting_bp
from .routes.chat_routes import bp as chatm_bp
from .routes.reminder_routes import reminder_bp
import app.sockets.meeting_socket


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    socketio.init_app(app, cors_allowed_origins="*")

    app.register_blueprint(bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(user_bp)
    app.register_blueprint(folder_bp)
    app.register_blueprint(file_bp)
    app.register_blueprint(chunk_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(meeting_bp)
    app.register_blueprint(chatm_bp)
    app.register_blueprint(reminder_bp)

    return app
