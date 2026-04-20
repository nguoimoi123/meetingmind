from flask import request
from flask_socketio import join_room
from app.extensions import socketio
from app.services.auth_token_service import verify_user_token


@socketio.on("connect")
def on_connect():
    user_id = request.args.get("user_id")
    access_token = request.args.get("access_token")
    token_user_id = verify_user_token(access_token) if access_token else None
    if not user_id or not token_user_id or str(token_user_id) != str(user_id):
        return False
    join_room(user_id)


@socketio.on("disconnect")
def on_disconnect():
    pass
