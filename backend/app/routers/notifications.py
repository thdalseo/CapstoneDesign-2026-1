from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import AppNotification, User
from app.notification_utils import create_notification, notification_dict

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


class NotificationCreateRequest(BaseModel):
    user_id: int
    type: str
    title: str
    body: str
    source_type: Optional[str] = None
    source_id: Optional[str] = None


class NotificationOwnerRequest(BaseModel):
    user_id: int


def _get_user(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
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
    user_id: int = Query(...),
    unread_only: bool = Query(default=False),
    limit: int = Query(default=80, ge=1, le=200),
    db: Session = Depends(get_db),
):
    _get_user(db, user_id)  # 존재 확인
    query = db.query(AppNotification).filter(AppNotification.user_id == user_id)
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
            AppNotification.user_id == user_id,
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
    _get_user(db, req.user_id)  # 존재 확인
    notification = create_notification(
        db,
        user_id=req.user_id,
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
    notification = _get_owned_notification(db, notification_id, req.user_id)
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return {"notification": notification_dict(notification)}


@router.patch("/read-all")
def mark_all_notifications_read(
    req: NotificationOwnerRequest,
    db: Session = Depends(get_db),
):
    _get_user(db, req.user_id)
    (
        db.query(AppNotification)
        .filter(AppNotification.user_id == req.user_id)
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
    notification = _get_owned_notification(db, notification_id, req.user_id)
    db.delete(notification)
    db.commit()
    return {"message": "Notification deleted."}


@router.delete("")
def clear_notifications(
    req: NotificationOwnerRequest,
    db: Session = Depends(get_db),
):
    _get_user(db, req.user_id)
    db.query(AppNotification).filter(AppNotification.user_id == req.user_id).delete()
    db.commit()
    return {"message": "Notifications cleared."}
