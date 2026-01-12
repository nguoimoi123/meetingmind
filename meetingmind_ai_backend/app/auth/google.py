from flask import Flask, request, jsonify
from google.oauth2 import id_token
from google.auth.transport import requests
import os

@app.route("/auth/google", methods=["POST"])
def google_login():
    data = request.json
    token = data.get("id_token")

    try:
        idinfo = id_token.verify_oauth2_token(
            token,
            requests.Request(),
            os.getenv("GOOGLE_CLIENT_ID")
        )

        email = idinfo["email"]
        name = idinfo.get("name")

        # TODO: save/find user in MongoDB

        return jsonify({"message": "Login success", "email": email}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 401
