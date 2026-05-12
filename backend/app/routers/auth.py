from datetime import datetime, timedelta

import bcrypt
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.email_verifier import send_verification_email
from app.models.user import EmailVerification, User

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
