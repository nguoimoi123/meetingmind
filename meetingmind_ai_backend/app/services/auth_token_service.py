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
    if not auth_header:
        return None

    prefix = "Bearer "
    if not auth_header.startswith(prefix):
        return None

    token = auth_header[len(prefix):].strip()
    return token or None
