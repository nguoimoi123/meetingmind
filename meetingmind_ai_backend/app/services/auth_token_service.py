from itsdangerous import BadSignature, BadTimeSignature, URLSafeTimedSerializer

from ..config import Config


_USER_TOKEN_SALT = "meetingmind-user-auth"


def _get_serializer():
    secret = Config.SECRET_KEY
    if not secret:
        raise RuntimeError("SECRET_KEY is not configured")
    return URLSafeTimedSerializer(secret_key=secret)


def issue_user_token(user_id: str) -> str:
    serializer = _get_serializer()
    return serializer.dumps({"user_id": str(user_id)}, salt=_USER_TOKEN_SALT)


def verify_user_token(token: str, max_age_seconds: int = 60 * 60 * 24 * 7):
    if not token:
        return None

    serializer = _get_serializer()
    try:
        payload = serializer.loads(
            token,
            salt=_USER_TOKEN_SALT,
            max_age=max_age_seconds,
        )
    except (BadSignature, BadTimeSignature):
        return None

    user_id = payload.get("user_id")
    return str(user_id) if user_id else None


def extract_bearer_token(request):
    auth_header = request.headers.get("Authorization", "").strip()
    if auth_header:
        prefix = "Bearer "
        if auth_header.startswith(prefix):
            token = auth_header[len(prefix):].strip()
            if token:
                return token

    token = request.headers.get("X-Access-Token", "").strip()
    if token:
        return token

    token = request.args.get("access_token", "").strip()
    if token:
        return token

    data = request.get_json(silent=True)
    if isinstance(data, dict):
        token = str(data.get("access_token") or "").strip()
        if token:
            return token

    return None
