"""
샘플 데이터 시딩 스크립트
실행: python seed_data.py  (backend/ 디렉터리에서)

Flutter match_service.dart 의 _mockMatches 와 동일한 유저를 DB에 삽입합니다.
백엔드 팀원이 실행하면 프론트엔드 매칭 API 테스트가 가능합니다.
"""

import bcrypt
from app.core.database import SessionLocal
from app.models.user import (
    User, UserInterest, UserPersonality, UserLanguage, UserExchangePurpose
)


def hash_pw(pw: str) -> str:
    return bcrypt.hashpw(pw.encode(), bcrypt.gensalt()).decode()


SEED_USERS = [
    {
        "email": "sofia@example.com",
        "password": "test1234!",
        "name": "Sofia",
        "country": "🇺🇸 미국",
        "college": "경영대학",
        "major": "경영학과",
        "year": "2학년",
        "description": "한국어 공부 중이에요! 같이 언어 교환해요 😊",
        "is_international": True,
        "interests": ["여행", "카페 탐방", "영화"],
        "personalities": ["외향적", "친화적"],
        "languages": ["영어", "한국어"],
        "purposes": ["언어교환", "친구사귀기"],
    },
    {
        "email": "liam@example.com",
        "password": "test1234!",
        "name": "Liam",
        "country": "🇬🇧 영국",
        "college": "IT대학",
        "major": "컴퓨터공학과",
        "year": "3학년",
        "description": "한국 문화에 관심이 많아요! 같이 공부도 하고 싶어요 📚",
        "is_international": True,
        "interests": ["게임", "음악", "K-POP"],
        "personalities": ["내향적", "계획적인"],
        "languages": ["영어", "한국어"],
        "purposes": ["언어교환", "학업도움"],
    },
    {
        "email": "amara@example.com",
        "password": "test1234!",
        "name": "Amara",
        "country": "🇳🇬 나이지리아",
        "college": "인문대학",
        "major": "국제학부",
        "year": "1학년",
        "description": "캠퍼스 생활 도움이 필요해요! 친하게 지내고 싶어요 😄",
        "is_international": True,
        "interests": ["요리", "운동", "사진"],
        "personalities": ["활발한", "유쾌한"],
        "languages": ["영어"],
        "purposes": ["친구사귀기", "문화교류"],
    },
    {
        "email": "yuki@example.com",
        "password": "test1234!",
        "name": "Yuki",
        "country": "🇯🇵 일본",
        "college": "인문대학",
        "major": "일어일문학과",
        "year": "2학년",
        "description": "한국 드라마를 정말 좋아해요. 한국어도 배우고 싶어요!",
        "is_international": True,
        "interests": ["독서", "드라마", "음악"],
        "personalities": ["차분한", "감성적인"],
        "languages": ["일본어", "한국어", "영어"],
        "purposes": ["언어교환", "문화교류"],
    },
    {
        "email": "marco@example.com",
        "password": "test1234!",
        "name": "Marco",
        "country": "🇮🇹 이탈리아",
        "college": "사범대학",
        "major": "체육교육과",
        "year": "4학년",
        "description": "축구 좋아하시는 분 같이 운동해요! 한국 음식도 너무 맛있어요 🍜",
        "is_international": True,
        "interests": ["스포츠", "여행", "요리"],
        "personalities": ["외향적", "활발한"],
        "languages": ["영어", "한국어"],
        "purposes": ["친구사귀기", "문화교류"],
    },
]


def seed():
    db = SessionLocal()
    try:
        for data in SEED_USERS:
            if db.query(User).filter(User.email == data["email"]).first():
                print(f"  이미 존재: {data['email']}")
                continue

            user = User(
                email=data["email"],
                password_hash=hash_pw(data["password"]),
                name=data["name"],
                country=data["country"],
                college=data["college"],
                major=data["major"],
                year=data["year"],
                description=data["description"],
                is_international=data["is_international"],
                is_verified=True,
            )
            db.add(user)
            db.flush()

            for i in data["interests"]:
                db.add(UserInterest(user_id=user.id, interest=i))
            for p in data["personalities"]:
                db.add(UserPersonality(user_id=user.id, personality=p))
            for lang in data["languages"]:
                db.add(UserLanguage(user_id=user.id, language=lang))
            for p in data["purposes"]:
                db.add(UserExchangePurpose(user_id=user.id, purpose=p))

            print(f"  추가됨: {data['name']} ({data['email']})")

        db.commit()
        print("시딩 완료!")
    except Exception as e:
        db.rollback()
        print(f"오류: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
