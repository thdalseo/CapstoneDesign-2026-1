from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import LanguageSession, User

router = APIRouter(prefix="/api/sessions", tags=["sessions"])


# ── 스키마 ────────────────────────────────────────────────────────────────────

class SessionCreateRequest(BaseModel):
    user_id: int
    partner_id: Optional[int] = None
    partner_name: str = ""
    teach_language: str
    learn_language: str
    minutes: int
    session_date: str   # "2026-06-02"


class SessionResponse(BaseModel):
    id: int
    user_id: int
    partner_id: Optional[int]
    partner_name: str
    teach_language: str
    learn_language: str
    minutes: int
    session_date: str
    created_at: str

    class Config:
        from_attributes = True


# ── 엔드포인트 ────────────────────────────────────────────────────────────────

@router.post("", response_model=SessionResponse)
def create_session(req: SessionCreateRequest, db: Session = Depends(get_db)):
    """세션 기록 저장."""
    # 유저 존재 확인
    user = db.query(User).filter(User.id == req.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    session = LanguageSession(
        user_id=req.user_id,
        partner_id=req.partner_id,
        partner_name=req.partner_name,
        teach_language=req.teach_language,
        learn_language=req.learn_language,
        minutes=req.minutes,
        session_date=req.session_date,
        created_at=datetime.utcnow(),
    )
    db.add(session)
    db.commit()
    db.refresh(session)

    return _to_response(session)


@router.get("", response_model=List[SessionResponse])
def get_sessions(user_id: int, db: Session = Depends(get_db)):
    """특정 유저의 전체 세션 기록 반환 (날짜 오름차순)."""
    sessions = (
        db.query(LanguageSession)
        .filter(LanguageSession.user_id == user_id)
        .order_by(LanguageSession.session_date, LanguageSession.created_at)
        .all()
    )
    return [_to_response(s) for s in sessions]


def _to_response(s: LanguageSession) -> dict:
    return {
        "id": s.id,
        "user_id": s.user_id,
        "partner_id": s.partner_id,
        "partner_name": s.partner_name,
        "teach_language": s.teach_language,
        "learn_language": s.learn_language,
        "minutes": s.minutes,
        "session_date": s.session_date,
        "created_at": s.created_at.strftime("%Y-%m-%dT%H:%M:%S"),
    }
