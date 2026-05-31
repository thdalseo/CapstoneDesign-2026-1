from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import LanguageExchangePost, User

router = APIRouter(prefix="/api/language-exchange", tags=["language-exchange"])


class LangExchangeCreateRequest(BaseModel):
    author_email: str
    native_language: str
    target_language: str
    memo: Optional[str] = None


def _get_user_by_email(db: Session, email: str) -> User:
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    return user


def _post_dict(post: LanguageExchangePost) -> dict:
    return {
        "id": post.id,
        "author_id": post.author_id,
        "authorName": post.author.name if post.author else "",
        "country": post.author.country if post.author else "",
        "major": post.author.major if post.author else "",
        "languages": [l.language for l in post.author.languages] if post.author else [],
        "native_language": post.native_language,
        "target_language": post.target_language,
        "memo": post.memo or "",
        "is_active": post.is_active,
        "created_at": post.created_at.isoformat() if post.created_at else None,
    }


@router.get("")
def list_posts(db: Session = Depends(get_db)):
    posts = (
        db.query(LanguageExchangePost)
        .filter(LanguageExchangePost.is_active.is_(True))
        .order_by(LanguageExchangePost.created_at.desc())
        .all()
    )
    return {"posts": [_post_dict(p) for p in posts]}


@router.get("/mine")
def list_my_posts(email: str, db: Session = Depends(get_db)):
    user = _get_user_by_email(db, email)
    posts = (
        db.query(LanguageExchangePost)
        .filter(LanguageExchangePost.author_id == user.id)
        .order_by(LanguageExchangePost.created_at.desc())
        .all()
    )
    return {"posts": [_post_dict(p) for p in posts]}


@router.post("")
def create_post(req: LangExchangeCreateRequest, db: Session = Depends(get_db)):
    author = _get_user_by_email(db, req.author_email)
    post = LanguageExchangePost(
        author_id=author.id,
        native_language=req.native_language,
        target_language=req.target_language,
        memo=req.memo,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return {"message": "Post created.", "post": _post_dict(post)}


@router.delete("/{post_id}")
def delete_post(post_id: int, db: Session = Depends(get_db)):
    post = (
        db.query(LanguageExchangePost)
        .filter(LanguageExchangePost.id == post_id)
        .first()
    )
    if not post:
        raise HTTPException(status_code=404, detail="Post not found.")
    db.delete(post)
    db.commit()
    return {"message": "Post deleted."}
