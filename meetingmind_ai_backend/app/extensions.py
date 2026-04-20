import os

from flask_mongoengine import MongoEngine
from flask_socketio import SocketIO


socketio = SocketIO(
    cors_allowed_origins="*",
    async_mode=os.getenv("SOCKETIO_ASYNC_MODE", "threading"),
)


db = MongoEngine()
