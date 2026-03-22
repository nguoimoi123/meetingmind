from app.extensions import socketio
from app.models.user_notification_model import UserNotification
from app.models.user_model import User
from mongoengine.errors import ValidationError


def serialize_notification(doc: UserNotification) -> dict:
    return {
        "id": str(doc.id),
        "user_id": doc.user_id,
        "title": doc.title,
        "body": doc.body,
        "type": doc.type,
        "payload": doc.payload or {},
        "is_read": doc.is_read,
        "created_at": doc.created_at.isoformat() if doc.created_at else None,
    }


def create_user_notification(
    *,
    user_id: str,
    title: str,
    body: str,
    notification_type: str = "system",
    payload: dict | None = None,
) -> UserNotification:
    doc = UserNotification(
        user_id=user_id,
        title=title,
        body=body,
        type=notification_type,
        payload=payload or {},
    )
    doc.save()

    socketio.emit("user_notification", serialize_notification(doc), room=user_id)
    return doc


def get_user_notifications(user_id: str, limit: int = 50):
    docs = UserNotification.objects(user_id=user_id).order_by("-created_at")[:limit]
    unread_count = UserNotification.objects(user_id=user_id, is_read=False).count()
    return {
        "notifications": [serialize_notification(doc) for doc in docs],
        "unread_count": unread_count,
    }


def mark_all_notifications_read(user_id: str) -> int:
    docs = UserNotification.objects(user_id=user_id, is_read=False)
    count = docs.count()
    if count:
        docs.update(set__is_read=True)
    return count


def delete_user_notification(user_id: str, notification_id: str) -> bool:
    try:
        doc = UserNotification.objects(
            id=notification_id,
            user_id=user_id,
        ).first()
    except ValidationError:
        return False

    if not doc:
        return False

    doc.delete()
    return True


def broadcast_user_notification(
    *,
    title: str,
    body: str,
    notification_type: str = "system",
    payload: dict | None = None,
    target_plan: str | None = None,
) -> int:
    query = User.objects
    if target_plan:
        query = query.filter(plan=target_plan)

    count = 0
    for user in query:
        create_user_notification(
            user_id=str(user.id),
            title=title,
            body=body,
            notification_type=notification_type,
            payload=payload or {},
        )
        count += 1
    return count
