from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import AppNotification, User
from app.notification_utils import create_notification, notification_dict

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


class NotificationCreateRequest(BaseModel):
    email: str
    type: str
    title: str
    body: str
    source_type: Optional[str] = None
    source_id: Optional[str] = None


class NotificationOwnerRequest(BaseModel):
    email: str


def _get_user_by_email(db: Session, email: str) -> User:
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    return user


def _get_owned_notification(
    db: Session,
    notification_id: int,
    user_id: int,
) -> AppNotification:
    notification = (
        db.query(AppNotification)
        .filter(
            AppNotification.id == notification_id,
            AppNotification.user_id == user_id,
        )
        .first()
    )
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found.")
    return notification


@router.get("")
def list_notifications(
    email: str = Query(...),
    unread_only: bool = Query(default=False),
    limit: int = Query(default=80, ge=1, le=200),
    db: Session = Depends(get_db),
):
    user = _get_user_by_email(db, email)
    query = db.query(AppNotification).filter(AppNotification.user_id == user.id)
    if unread_only:
        query = query.filter(AppNotification.is_read.is_(False))

    notifications = (
        query.order_by(AppNotification.created_at.desc())
        .limit(limit)
        .all()
    )
    unread_count = (
        db.query(AppNotification)
        .filter(
            AppNotification.user_id == user.id,
            AppNotification.is_read.is_(False),
        )
        .count()
    )
    return {
        "notifications": [notification_dict(item) for item in notifications],
        "unreadCount": unread_count,
    }


@router.post("")
def create_user_notification(
    req: NotificationCreateRequest,
    db: Session = Depends(get_db),
):
    user = _get_user_by_email(db, req.email)
    notification = create_notification(
        db,
        user_id=user.id,
        type=req.type,
        title=req.title,
        body=req.body,
        source_type=req.source_type,
        source_id=req.source_id,
    )
    db.commit()
    db.refresh(notification)
    return {
        "message": "Notification created.",
        "notification": notification_dict(notification),
    }


@router.patch("/{notification_id}/read")
def mark_notification_read(
    notification_id: int,
    req: NotificationOwnerRequest,
    db: Session = Depends(get_db),
):
    user = _get_user_by_email(db, req.email)
    notification = _get_owned_notification(db, notification_id, user.id)
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return {"notification": notification_dict(notification)}


@router.patch("/read-all")
def mark_all_notifications_read(
    req: NotificationOwnerRequest,
    db: Session = Depends(get_db),
):
    user = _get_user_by_email(db, req.email)
    (
        db.query(AppNotification)
        .filter(AppNotification.user_id == user.id)
        .update({"is_read": True})
    )
    db.commit()
    return {"message": "All notifications marked as read."}


@router.delete("/{notification_id}")
def delete_notification(
    notification_id: int,
    req: NotificationOwnerRequest,
    db: Session = Depends(get_db),
):
    user = _get_user_by_email(db, req.email)
    notification = _get_owned_notification(db, notification_id, user.id)
    db.delete(notification)
    db.commit()
    return {"message": "Notification deleted."}


@router.delete("")
def clear_notifications(
    req: NotificationOwnerRequest,
    db: Session = Depends(get_db),
):
    user = _get_user_by_email(db, req.email)
    db.query(AppNotification).filter(AppNotification.user_id == user.id).delete()
    db.commit()
    return {"message": "Notifications cleared."}
