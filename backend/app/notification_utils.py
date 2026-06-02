from sqlalchemy.orm import Session

from app.models.user import AppNotification


def notification_dict(notification: AppNotification) -> dict:
    return {
        "id": str(notification.id),
        "serverId": notification.id,
        "type": notification.type,
        "title": notification.title,
        "body": notification.body,
        "sourceType": notification.source_type,
        "sourceId": notification.source_id,
        "isRead": notification.is_read,
        "createdAt": notification.created_at.isoformat()
        if notification.created_at
        else None,
    }


def create_notification(
    db: Session,
    *,
    user_id: int,
    type: str,
    title: str,
    body: str,
    source_type: str | None = None,
    source_id: str | None = None,
    dedupe_key: str | None = None,
) -> AppNotification:
    if dedupe_key:
        existing = (
            db.query(AppNotification)
            .filter(
                AppNotification.user_id == user_id,
                AppNotification.dedupe_key == dedupe_key,
            )
            .first()
        )
        if existing:
            return existing

    notification = AppNotification(
        user_id=user_id,
        type=type,
        title=title,
        body=body,
        source_type=source_type,
        source_id=source_id,
        dedupe_key=dedupe_key,
        is_read=False,
    )
    db.add(notification)
    db.flush()
    return notification
