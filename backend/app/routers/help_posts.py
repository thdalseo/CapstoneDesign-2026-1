import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.profanity_filter import contains_profanity
from app.models.user import HelpHelper, HelpPost, User
from app.notification_utils import create_notification

router = APIRouter(prefix="/api/help-posts", tags=["help-posts"])


class HelpPostCreateRequest(BaseModel):
    author_email: str
    category: str
    title: str
    place: str
    date: datetime.date
    time: datetime.time
    memo: Optional[str] = None
    is_urgent: bool = False


class HelpPostUpdateRequest(BaseModel):
    category: Optional[str] = None
    title: Optional[str] = None
    place: Optional[str] = None
    date: Optional[datetime.date] = None
    time: Optional[datetime.time] = None
    memo: Optional[str] = None
    is_urgent: Optional[bool] = None
    is_completed: Optional[bool] = None


class HelpRequest(BaseModel):
    helper_email: str


def _get_user_by_email(db: Session, email: str) -> User:
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    return user


def _get_post(db: Session, post_id: int) -> HelpPost:
    post = db.query(HelpPost).filter(HelpPost.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Help post not found.")
    return post


def _post_dict(post: HelpPost) -> dict:
    return {
        "id": post.id,
        "category": post.category,
        "title": post.title,
        "author_id": post.author_id,
        "authorName": post.author.name if post.author else "",
        "country": post.author.country if post.author else "",
        "major": post.author.major if post.author else "",
        "place": post.place,
        "date": post.date.isoformat(),
        "time": post.time.strftime("%H:%M"),
        "memo": post.memo,
        "isUrgent": post.is_urgent,
        "isCompleted": post.is_completed,
        "helperCount": len(post.helpers),
        "helpers": [
            {
                "id": helper.helper.id,
                "name": helper.helper.name,
                "email": helper.helper.email,
            }
            for helper in post.helpers
            if helper.helper
        ],
        "createdAt": post.created_at.isoformat() + "Z" if post.created_at else None,
    }


@router.get("")
def list_help_posts(
    category: Optional[str] = Query(default=None),
    urgent_only: bool = Query(default=False),
    db: Session = Depends(get_db),
):
    query = db.query(HelpPost)
    if category:
        query = query.filter(HelpPost.category == category)
    if urgent_only:
        query = query.filter(HelpPost.is_urgent.is_(True))

    posts = query.order_by(HelpPost.is_urgent.desc(), HelpPost.created_at.desc()).all()
    return {"posts": [_post_dict(post) for post in posts]}


@router.get("/mine")
def list_my_help_posts(email: str = Query(...), db: Session = Depends(get_db)):
    user = _get_user_by_email(db, email)
    posts = (
        db.query(HelpPost)
        .filter(HelpPost.author_id == user.id)
        .order_by(HelpPost.created_at.desc())
        .all()
    )
    return {"posts": [_post_dict(post) for post in posts]}


@router.post("")
def create_help_post(req: HelpPostCreateRequest, db: Session = Depends(get_db)):
    # 금칙어 검사
    check_fields = [req.title, req.memo or ""]
    if any(contains_profanity(f) for f in check_fields):
        raise HTTPException(status_code=400, detail="부적절한 표현이 포함되어 있어요.")

    author = _get_user_by_email(db, req.author_email)
    post = HelpPost(
        author_id=author.id,
        category=req.category,
        title=req.title,
        place=req.place,
        date=req.date,
        time=req.time,
        memo=req.memo,
        is_urgent=req.is_urgent,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return {"message": "Help post created.", "post": _post_dict(post)}


@router.put("/{post_id}")
def update_help_post(
    post_id: int, req: HelpPostUpdateRequest, db: Session = Depends(get_db)
):
    # 금칙어 검사
    check_fields = [req.title or "", req.memo or ""]
    if any(contains_profanity(f) for f in check_fields):
        raise HTTPException(status_code=400, detail="부적절한 표현이 포함되어 있어요.")

    post = _get_post(db, post_id)
    updates = req.model_dump(exclude_unset=True)
    field_map = {
        "is_urgent": "is_urgent",
        "is_completed": "is_completed",
    }

    for key, value in updates.items():
        setattr(post, field_map.get(key, key), value)

    db.commit()
    db.refresh(post)
    return {"message": "Help post updated.", "post": _post_dict(post)}


@router.patch("/{post_id}/complete")
def complete_help_post(post_id: int, db: Session = Depends(get_db)):
    post = _get_post(db, post_id)
    post.is_completed = True
    for helper in post.helpers:
        create_notification(
            db,
            user_id=helper.helper_id,
            type="help",
            title="도움 요청 완료",
            body=f"'{post.title}' 도움 요청이 완료 처리되었습니다.",
            source_type="help_post",
            source_id=str(post.id),
            dedupe_key=f"help_complete:{post.id}:{helper.helper_id}",
        )
    db.commit()
    db.refresh(post)
    return {"message": "Help post completed.", "post": _post_dict(post)}


@router.post("/{post_id}/helpers")
def apply_help(post_id: int, req: HelpRequest, db: Session = Depends(get_db)):
    post = _get_post(db, post_id)
    helper = _get_user_by_email(db, req.helper_email)

    if post.author_id == helper.id:
        raise HTTPException(status_code=400, detail="Author cannot help own post.")

    existing = (
        db.query(HelpHelper)
        .filter(HelpHelper.post_id == post.id, HelpHelper.helper_id == helper.id)
        .first()
    )
    if existing:
        raise HTTPException(status_code=409, detail="Already applied to help.")

    db.add(HelpHelper(post_id=post.id, helper_id=helper.id))
    create_notification(
        db,
        user_id=post.author_id,
        type="help",
        title="새 도움 신청",
        body=f"{helper.name}님이 '{post.title}' 도움을 신청했습니다.",
        source_type="help_post",
        source_id=str(post.id),
        dedupe_key=f"help_apply:{post.id}:{helper.id}",
    )
    db.commit()
    db.refresh(post)
    return {"message": "Help application created.", "post": _post_dict(post)}


@router.delete("/{post_id}")
def delete_help_post(post_id: int, db: Session = Depends(get_db)):
    post = _get_post(db, post_id)
    db.delete(post)
    db.commit()
    return {"message": "Help post deleted."}
