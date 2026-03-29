from flask import request
from flask_socketio import join_room
from app.extensions import socketio
from app.services.auth_token_service import verify_user_token


@socketio.on("connect")
def on_connect():
    user_id = request.args.get("user_id")
    access_token = request.args.get("access_token")
    token_user_id = verify_user_token(access_token) if access_token else None
    if user_id and token_user_id and str(token_user_id) == str(user_id):
        join_room(user_id)


@socketio.on("disconnect")
def on_disconnect():
    pass
