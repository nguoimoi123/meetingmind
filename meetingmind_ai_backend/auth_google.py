from flask import Blueprint, request, jsonify
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from jose import jwt
from datetime import datetime, timedelta
import os

from database import users_col
from models.user_model import user_schema_google

auth_bp = Blueprint("auth", __name__, url_prefix="/auth")

@auth_bp.route("/google", methods=["POST"])
def google_login():
    token = request.json.get("token")

    idinfo = id_token.verify_oauth2_token(
        token,
        google_requests.Request(),
        os.getenv("GOOGLE_OAUTH_CLIENT_ID")
    )

    email = idinfo["email"]
    name = idinfo.get("name")
    avatar = idinfo.get("picture")

    user = users_col.find_one({"email": email})

    if not user:
        user = user_schema_google(email, name, avatar)
        users_col.insert_one(user)

    payload = {
        "sub": str(user["_id"]),
        "exp": datetime.utcnow() + timedelta(days=7)
    }

    access_token = jwt.encode(payload, os.getenv("JWT_SECRET"), algorithm="HS256")

    return jsonify({
        "access_token": access_token,
        "user": {
            "id": str(user["_id"]),
            "email": email,
            "name": name,
            "avatar": avatar
        }
    })
