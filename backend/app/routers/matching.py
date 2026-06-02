from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import Match, User

router = APIRouter(prefix="/api", tags=["matching"])


class WeightUpdateRequest(BaseModel):
    weight_purpose: int
    weight_interests: int
    weight_language: int
    weight_personality: int
    weight_major: int
    weight_year: int
    weight_nationality: int


class SelectedMatchRequest(BaseModel):
    email: str
    matched_user_id: int
    match_score: int | None = None


def _values(rows, attr: str) -> set[str]:
    return {
        str(value).strip()
        for row in rows
        for value in [getattr(row, attr, "")]
        if str(value).strip()
    }


def _overlap_score(left: set[str], right: set[str], weight: int) -> int:
    if not left or not right or weight <= 0:
        return 0
    denominator = max(len(left), len(right))
    return round(weight * (len(left & right) / denominator))


def _same_score(left: str | None, right: str | None, weight: int) -> int:
    if not left or not right or weight <= 0:
        return 0
    return weight if left == right else 0


def _different_score(left: str | None, right: str | None, weight: int) -> int:
    if not left or not right or weight <= 0:
        return 0
    return weight if left != right else 0


def _weights(user: User) -> dict[str, int]:
    return {
        "purpose": user.weight_purpose or 0,
        "interests": user.weight_interests or 0,
        "language": user.weight_language or 0,
        "personality": user.weight_personality or 0,
        "major": user.weight_major or 0,
        "year": user.weight_year or 0,
        "nationality": user.weight_nationality or 0,
    }


def _score(me: User, other: User) -> int:
    weights = _weights(me)
    score = 0
    score += _overlap_score(
        _values(me.exchange_purposes, "purpose"),
        _values(other.exchange_purposes, "purpose"),
        weights["purpose"],
    )
    score += _overlap_score(
        _values(me.interests, "interest"),
        _values(other.interests, "interest"),
        weights["interests"],
    )
    score += _overlap_score(
        _values(me.languages, "language"),
        _values(other.languages, "language"),
        weights["language"],
    )
    score += _overlap_score(
        _values(me.personalities, "personality"),
        _values(other.personalities, "personality"),
        weights["personality"],
    )
    score += _same_score(me.major, other.major, weights["major"])
    score += _same_score(me.year, other.year, weights["year"])
    score += _different_score(me.country, other.country, weights["nationality"])
    return max(0, min(100, score))


def _match_dict(user: User, score: int) -> dict:
    return {
        "id": user.id,
        "name": user.name,
        "country": user.country,
        "college": user.college,
        "major": user.major,
        "year": user.year or "",
        "interests": [row.interest for row in user.interests],
        "exchange_purposes": [row.purpose for row in user.exchange_purposes],
        "personalities": [row.personality for row in user.personalities],
        "languages": [row.language for row in user.languages],
        "description": user.description or "",
        "match_score": score,
    }


def _validate_weight_sum(req: WeightUpdateRequest) -> None:
    weights = [
        req.weight_purpose,
        req.weight_interests,
        req.weight_language,
        req.weight_personality,
        req.weight_major,
        req.weight_year,
        req.weight_nationality,
    ]
    if any(weight < 0 for weight in weights):
        raise HTTPException(status_code=400, detail="Weights must be non-negative.")
    if sum(weights) != 100:
        raise HTTPException(status_code=400, detail="Weights must sum to 100.")


def _get_user_by_email(db: Session, email: str) -> User:
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    return user


def _get_user_by_id(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Matched user not found.")
    return user


def _pair(user_id_a: int, user_id_b: int) -> tuple[int, int]:
    if user_id_a == user_id_b:
        raise HTTPException(status_code=400, detail="Cannot match yourself.")
    return tuple(sorted((user_id_a, user_id_b)))


@router.get("/matching")
def list_matching(email: str, limit: int = 20, db: Session = Depends(get_db)):
    me = _get_user_by_email(db, email)

    users = db.query(User).filter(User.id != me.id).all()
    ranked = [(_score(me, other), other) for other in users]
    ranked.sort(key=lambda item: (-item[0], item[1].id))
    return [_match_dict(user, score) for score, user in ranked[:limit]]


@router.get("/matching/selected")
def list_selected_matches(email: str, db: Session = Depends(get_db)):
    me = _get_user_by_email(db, email)
    rows = (
        db.query(Match)
        .filter(
            Match.is_active.is_(True),
            ((Match.user_id_a == me.id) | (Match.user_id_b == me.id)),
        )
        .order_by(Match.created_at.desc())
        .all()
    )

    result = []
    for row in rows:
        other = row.user_b if row.user_id_a == me.id else row.user_a
        if other:
            result.append(_match_dict(other, row.match_score))
    return result


@router.post("/matching/selected")
def select_match(req: SelectedMatchRequest, db: Session = Depends(get_db)):
    me = _get_user_by_email(db, req.email)
    other = _get_user_by_id(db, req.matched_user_id)
    user_id_a, user_id_b = _pair(me.id, other.id)
    score = req.match_score if req.match_score is not None else _score(me, other)
    score = max(0, min(100, score))

    row = (
        db.query(Match)
        .filter(Match.user_id_a == user_id_a, Match.user_id_b == user_id_b)
        .first()
    )
    if row:
        row.match_score = score
        row.is_active = True
    else:
        row = Match(
            user_id_a=user_id_a,
            user_id_b=user_id_b,
            match_score=score,
            is_active=True,
        )
        db.add(row)

    db.commit()
    db.refresh(row)
    return {"message": "Match selected.", "match": _match_dict(other, row.match_score)}


@router.delete("/matching/selected/{matched_user_id}")
def unselect_match(matched_user_id: int, email: str, db: Session = Depends(get_db)):
    me = _get_user_by_email(db, email)
    other = _get_user_by_id(db, matched_user_id)
    user_id_a, user_id_b = _pair(me.id, other.id)

    row = (
        db.query(Match)
        .filter(Match.user_id_a == user_id_a, Match.user_id_b == user_id_b)
        .first()
    )
    if not row:
        return {"message": "Match already removed."}

    row.is_active = False
    db.commit()
    return {"message": "Match removed."}


@router.put("/users/{email}/weights")
def update_weights(
    email: str,
    req: WeightUpdateRequest,
    db: Session = Depends(get_db),
):
    _validate_weight_sum(req)

    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    user.weight_purpose = req.weight_purpose
    user.weight_interests = req.weight_interests
    user.weight_language = req.weight_language
    user.weight_personality = req.weight_personality
    user.weight_major = req.weight_major
    user.weight_year = req.weight_year
    user.weight_nationality = req.weight_nationality
    db.commit()
    db.refresh(user)

    return {
        "message": "Weights updated.",
        "weights": _weights(user),
    }
