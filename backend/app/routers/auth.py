from datetime import datetime, timedelta
from typing import List, Optional

import bcrypt
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.profanity_filter import contains_profanity
from app.email_verifier import send_verification_email
from app.models.user import (
    EmailVerification,
    User,
    UserInterest,
    UserExchangePurpose,
    UserLanguage,
    UserPersonality,
)

router = APIRouter(prefix="/auth", tags=["auth"])

CODE_EXPIRE_MINUTES = 10


# ── helpers ───────────────────────────────────────────────────────────────────

def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def _verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())


def _user_dict(user: User) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "country": user.country,
        "college": user.college,
        "major": user.major,
        "year": user.year,
        "description": user.description,
        "avatar_url": user.avatar_url,
        "is_international": user.is_international,
        "interests": [i.interest for i in user.interests],
        "exchange_purposes": [p.purpose for p in user.exchange_purposes],
        "personalities": [p.personality for p in user.personalities],
        "languages": [l.language for l in user.languages],
        "weight_purpose": user.weight_purpose,
        "weight_interests": user.weight_interests,
        "weight_language": user.weight_language,
        "weight_personality": user.weight_personality,
        "weight_major": user.weight_major,
        "weight_year": user.weight_year,
        "weight_nationality": user.weight_nationality,
    }


# ── schemas ───────────────────────────────────────────────────────────────────

class SendCodeRequest(BaseModel):
    email: str


class RegisterRequest(BaseModel):
    email: str
    code: str
    password: str
    name: str
    country: str
    college: str
    major: str


class LoginRequest(BaseModel):
    email: str
    password: str


class DeleteAccountRequest(BaseModel):
    email: str
    password: str


class UpdateProfileRequest(BaseModel):
    email: str
    year: Optional[str] = None
    description: Optional[str] = None
    avatar_url: Optional[str] = None
    interests: Optional[List[str]] = None
    exchange_purposes: Optional[List[str]] = None
    personalities: Optional[List[str]] = None
    languages: Optional[List[str]] = None
    weight_purpose: Optional[int] = None
    weight_interests: Optional[int] = None
    weight_language: Optional[int] = None
    weight_personality: Optional[int] = None
    weight_major: Optional[int] = None
    weight_year: Optional[int] = None
    weight_nationality: Optional[int] = None


# ── endpoints ─────────────────────────────────────────────────────────────────

@router.post("/send-code")
def send_code(req: SendCodeRequest, db: Session = Depends(get_db)):
    code, message = send_verification_email(req.email)
    if code is None:
        raise HTTPException(status_code=400, detail=message)

    expires_at = datetime.utcnow() + timedelta(minutes=CODE_EXPIRE_MINUTES)
    record = db.query(EmailVerification).filter(EmailVerification.email == req.email).first()
    if record:
        record.code = code
        record.expires_at = expires_at
        record.is_verified = False
        record.created_at = datetime.utcnow()
    else:
        record = EmailVerification(
            email=req.email,
            code=code,
            expires_at=expires_at,
            is_verified=False,
        )
        db.add(record)

    db.commit()
    return {"message": "인증 코드가 발송되었습니다."}


@router.post("/register")
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    record = db.query(EmailVerification).filter(EmailVerification.email == req.email).first()
    if not record:
        raise HTTPException(status_code=404, detail="인증 코드를 먼저 요청해주세요.")
    if record.is_verified:
        raise HTTPException(status_code=400, detail="이미 인증 완료된 이메일입니다.")
    if datetime.utcnow() > record.expires_at:
        raise HTTPException(status_code=400, detail="인증 코드가 만료되었습니다. 다시 요청해주세요.")
    if record.code != req.code:
        raise HTTPException(status_code=400, detail="인증 코드가 올바르지 않습니다.")

    existing = db.query(User).filter(User.email == req.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="이미 가입된 이메일입니다.")

    user = User(
        email=req.email,
        password_hash=_hash_password(req.password),
        name=req.name,
        country=req.country,
        college=req.college,
        major=req.major,
        is_verified=True,
        is_international=(req.country != "대한민국"),
    )
    db.add(user)
    record.is_verified = True
    db.commit()
    db.refresh(user)

    return {"message": "회원가입이 완료되었습니다.", "user": _user_dict(user)}


@router.delete("/me")
def delete_account(req: DeleteAccountRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or not _verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=401, detail="이메일 또는 비밀번호가 올바르지 않습니다.")

    db.delete(user)
    db.commit()
    return {"message": "회원탈퇴가 완료되었습니다."}


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or not _verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=401, detail="이메일 또는 비밀번호가 올바르지 않습니다.")
    if not user.is_verified:
        raise HTTPException(status_code=403, detail="이메일 인증이 필요합니다.")

    return {"message": "로그인 성공", "user": _user_dict(user)}


@router.get("/profile")
def get_profile(email: str, db: Session = Depends(get_db)):
    """이메일로 프로필 조회 — 앱 시작 시 최신 데이터 동기화용"""
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return {"user": _user_dict(user)}


@router.patch("/profile")
def update_profile(req: UpdateProfileRequest, db: Session = Depends(get_db)):
    """프로필 편집 내용을 DB에 저장"""
    user = db.query(User).filter(User.email == req.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    # 금칙어 검사 (자기소개)
    if req.description and contains_profanity(req.description):
        raise HTTPException(status_code=400, detail="부적절한 표현이 포함되어 있어요.")

    # 단순 필드
    if req.year is not None:
        user.year = req.year
    if req.description is not None:
        user.description = req.description
    # avatar_url은 로컬 파일 경로일 수 있으므로 http URL일 때만 저장
    if req.avatar_url is not None and req.avatar_url.startswith("http"):
        user.avatar_url = req.avatar_url

    # 관심사 (전체 교체)
    if req.interests is not None:
        db.query(UserInterest).filter(UserInterest.user_id == user.id).delete()
        for item in req.interests:
            db.add(UserInterest(user_id=user.id, interest=item))

    # 교류 목적 (전체 교체)
    if req.exchange_purposes is not None:
        db.query(UserExchangePurpose).filter(UserExchangePurpose.user_id == user.id).delete()
        valid_purposes = {"언어교환", "학업도움", "친구사귀기", "문화교류"}
        for item in req.exchange_purposes:
            if item in valid_purposes:
                db.add(UserExchangePurpose(user_id=user.id, purpose=item))

    # 성향 (전체 교체)
    if req.personalities is not None:
        db.query(UserPersonality).filter(UserPersonality.user_id == user.id).delete()
        for item in req.personalities:
            db.add(UserPersonality(user_id=user.id, personality=item))

    # 언어 (전체 교체)
    if req.languages is not None:
        db.query(UserLanguage).filter(UserLanguage.user_id == user.id).delete()
        for item in req.languages:
            db.add(UserLanguage(user_id=user.id, language=item))

    # 매칭 가중치
    if req.weight_purpose is not None:
        user.weight_purpose = req.weight_purpose
    if req.weight_interests is not None:
        user.weight_interests = req.weight_interests
    if req.weight_language is not None:
        user.weight_language = req.weight_language
    if req.weight_personality is not None:
        user.weight_personality = req.weight_personality
    if req.weight_major is not None:
        user.weight_major = req.weight_major
    if req.weight_year is not None:
        user.weight_year = req.weight_year
    if req.weight_nationality is not None:
        user.weight_nationality = req.weight_nationality

    db.commit()
    db.refresh(user)
    return {"message": "프로필이 업데이트되었습니다.", "user": _user_dict(user)}
