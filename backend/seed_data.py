"""
샘플 데이터 시딩 스크립트
실행: python seed_data.py  (backend/ 디렉터리에서)

Flutter match_service.dart 의 _mockMatches 와 같은 순서의 유저를 DB에 삽입/갱신합니다.
테스트 계정 공통 비밀번호: test1234!
"""

import bcrypt

from app.core.database import SessionLocal
from app.models.user import (
    User,
    UserExchangePurpose,
    UserInterest,
    UserLanguage,
    UserPersonality,
)


VALID_INTERESTS = {
    "여행", "카페 탐방", "영화", "음악", "운동",
    "K-POP", "요리", "사진", "독서", "게임",
    "드라마", "패션", "뷰티", "스포츠", "언어",
}
VALID_PERSONALITIES = {
    "외향적", "내향적", "친화적", "차분한", "계획적인",
    "유쾌한", "진지한", "활발한", "감성적인", "호기심 많은",
}
VALID_LANGUAGES = {
    "한국어", "영어", "중국어", "일본어", "베트남어",
    "프랑스어", "독일어", "스페인어", "러시아어", "아랍어",
}
VALID_PURPOSES = {"언어교환", "학업도움", "친구사귀기", "문화교류"}


def hash_pw(pw: str) -> str:
    return bcrypt.hashpw(pw.encode(), bcrypt.gensalt()).decode()


SEED_USERS = [
    # Existing foreign sample users kept first to preserve the usual local id order.
    {
        "email": "sofia@example.com",
        "password": "test1234!",
        "name": "Sofia",
        "country": "🇺🇸 미국",
        "college": "경영대학",
        "major": "경영학과",
        "year": "2학년",
        "description": "한국어 공부 중이에요! 같이 언어 교환해요",
        "is_international": True,
        "interests": ["여행", "카페 탐방", "영화"],
        "personalities": ["외향적", "친화적"],
        "languages": ["영어", "한국어"],
        "purposes": ["언어교환", "친구사귀기"],
        # 언어 교환에 최우선 가중치
        "weight_language": 35, "weight_purpose": 25, "weight_interests": 20,
        "weight_personality": 10, "weight_major": 5, "weight_year": 3, "weight_nationality": 2,
    },
    {
        "email": "liam@example.com",
        "password": "test1234!",
        "name": "Liam",
        "country": "🇬🇧 영국",
        "college": "IT대학",
        "major": "컴퓨터공학과",
        "year": "3학년",
        "description": "한국 문화와 코딩 공부에 관심이 많아요",
        "is_international": True,
        "interests": ["게임", "음악", "K-POP"],
        "personalities": ["내향적", "계획적인"],
        "languages": ["영어", "한국어"],
        "purposes": ["언어교환", "학업도움"],
        # 교류 목적·전공 일치를 중시
        "weight_purpose": 30, "weight_major": 25, "weight_language": 20,
        "weight_interests": 10, "weight_personality": 8, "weight_year": 5, "weight_nationality": 2,
    },
    {
        "email": "amara@example.com",
        "password": "test1234!",
        "name": "Amara",
        "country": "🇳🇬 나이지리아",
        "college": "사회과학대학",
        "major": "국제학부",
        "year": "1학년",
        "description": "캠퍼스 생활을 배우며 친구를 만들고 싶어요",
        "is_international": True,
        "interests": ["요리", "운동", "사진"],
        "personalities": ["활발한", "유쾌한"],
        "languages": ["영어"],
        "purposes": ["친구사귀기", "문화교류"],
        # 성향·성격 일치를 가장 중시
        "weight_personality": 35, "weight_purpose": 25, "weight_interests": 20,
        "weight_language": 10, "weight_major": 5, "weight_year": 3, "weight_nationality": 2,
    },
    {
        "email": "yuki@example.com",
        "password": "test1234!",
        "name": "Yuki",
        "country": "🇯🇵 일본",
        "college": "인문대학",
        "major": "일어일문학과",
        "year": "2학년",
        "description": "한국 드라마와 한국어를 같이 배우고 싶어요",
        "is_international": True,
        "interests": ["독서", "드라마", "음악"],
        "personalities": ["차분한", "감성적인"],
        "languages": ["일본어", "한국어", "영어"],
        "purposes": ["언어교환", "문화교류"],
        # 언어·국적(한국인 파트너 선호)을 중시
        "weight_language": 30, "weight_nationality": 25, "weight_purpose": 20,
        "weight_interests": 15, "weight_personality": 5, "weight_major": 3, "weight_year": 2,
    },
    {
        "email": "marco@example.com",
        "password": "test1234!",
        "name": "Marco",
        "country": "🇮🇹 이탈리아",
        "college": "사범대학",
        "major": "체육교육과",
        "year": "4학년",
        "description": "축구와 한국 음식을 좋아해요",
        "is_international": True,
        "interests": ["스포츠", "여행", "요리"],
        "personalities": ["외향적", "활발한"],
        "languages": ["영어", "한국어"],
        "purposes": ["친구사귀기", "문화교류"],
        # 공통 관심사 최우선
        "weight_interests": 35, "weight_personality": 25, "weight_purpose": 20,
        "weight_language": 10, "weight_nationality": 5, "weight_major": 3, "weight_year": 2,
    },

    # Korean sample users.
    {
        "email": "minji@example.com",
        "password": "test1234!",
        "name": "김민지",
        "country": "🇰🇷 대한민국",
        "college": "공과대학",
        "major": "컴퓨터공학과",
        "year": "3학년",
        "description": "코딩 공부와 언어 교환을 같이 하고 싶어요",
        "is_international": False,
        "interests": ["게임", "K-POP", "카페 탐방"],
        "personalities": ["내향적", "계획적인", "진지한"],
        "languages": ["한국어", "영어"],
        "purposes": ["언어교환", "학업도움"],
        # 전공·언어 중시 (같은 컴공 파트너 선호)
        "weight_major": 30, "weight_language": 25, "weight_purpose": 20,
        "weight_interests": 15, "weight_personality": 5, "weight_year": 3, "weight_nationality": 2,
    },
    {
        "email": "jaehyun@example.com",
        "password": "test1234!",
        "name": "박재현",
        "country": "🇰🇷 대한민국",
        "college": "경영대학",
        "major": "경영학과",
        "year": "2학년",
        "description": "발표 연습과 카페 탐방을 좋아해요",
        "is_international": False,
        "interests": ["카페 탐방", "영화", "패션"],
        "personalities": ["외향적", "친화적"],
        "languages": ["한국어", "영어"],
        "purposes": ["친구사귀기", "학업도움"],
        # 성격·관심사 위주 (소셜형)
        "weight_personality": 30, "weight_interests": 25, "weight_purpose": 20,
        "weight_language": 15, "weight_major": 5, "weight_year": 3, "weight_nationality": 2,
    },
    {
        "email": "seoah@example.com",
        "password": "test1234!",
        "name": "이서아",
        "country": "🇰🇷 대한민국",
        "college": "인문대학",
        "major": "영어영문학과",
        "year": "4학년",
        "description": "영어 회화와 영화 이야기를 나누고 싶어요",
        "is_international": False,
        "interests": ["영화", "독서", "언어"],
        "personalities": ["차분한", "감성적인"],
        "languages": ["한국어", "영어", "일본어"],
        "purposes": ["언어교환", "문화교류"],
        # 언어 능력 최중시 (어학 전문가형)
        "weight_language": 35, "weight_purpose": 25, "weight_interests": 20,
        "weight_nationality": 10, "weight_personality": 5, "weight_major": 3, "weight_year": 2,
    },
    {
        "email": "doyun@example.com",
        "password": "test1234!",
        "name": "최도윤",
        "country": "🇰🇷 대한민국",
        "college": "IT대학",
        "major": "컴퓨터공학과",
        "year": "1학년",
        "description": "게임과 K-POP 이야기할 친구를 찾아요",
        "is_international": False,
        "interests": ["게임", "K-POP", "음악"],
        "personalities": ["호기심 많은", "유쾌한"],
        "languages": ["한국어"],
        "purposes": ["친구사귀기"],
        # 관심사 절대 최우선 (취미 중심형)
        "weight_interests": 40, "weight_personality": 25, "weight_purpose": 20,
        "weight_language": 8, "weight_major": 4, "weight_year": 2, "weight_nationality": 1,
    },
    {
        "email": "yuna@example.com",
        "password": "test1234!",
        "name": "정유나",
        "country": "🇰🇷 대한민국",
        "college": "사회과학대학",
        "major": "행정학과",
        "year": "2학년",
        "description": "캠퍼스 생활 정보를 나누고 싶어요",
        "is_international": False,
        "interests": ["여행", "사진", "드라마"],
        "personalities": ["친화적", "계획적인"],
        "languages": ["한국어", "중국어"],
        "purposes": ["문화교류", "친구사귀기"],
        # 학년 근접 중시 (비슷한 학번 선호)
        "weight_year": 30, "weight_personality": 25, "weight_interests": 20,
        "weight_purpose": 15, "weight_language": 5, "weight_major": 3, "weight_nationality": 2,
    },
    {
        "email": "hyunwoo@example.com",
        "password": "test1234!",
        "name": "강현우",
        "country": "🇰🇷 대한민국",
        "college": "사범대학",
        "major": "체육교육과",
        "year": "4학년",
        "description": "운동 같이 하고 한국 문화를 알려줄게요",
        "is_international": False,
        "interests": ["운동", "스포츠", "여행"],
        "personalities": ["외향적", "활발한"],
        "languages": ["한국어", "영어"],
        "purposes": ["친구사귀기", "문화교류"],
        # 국적 다양성 + 관심사·성격 고루 중시
        "weight_nationality": 20, "weight_interests": 25, "weight_personality": 25,
        "weight_purpose": 15, "weight_language": 8, "weight_major": 5, "weight_year": 2,
    },
    {
        "email": "sujin@example.com",
        "password": "test1234!",
        "name": "오수진",
        "country": "🇰🇷 대한민국",
        "college": "문화예술대학",
        "major": "디자인학과",
        "year": "3학년",
        "description": "사진과 전시 보러 다니는 걸 좋아해요",
        "is_international": False,
        "interests": ["사진", "패션", "뷰티"],
        "personalities": ["감성적인", "차분한"],
        "languages": ["한국어", "프랑스어"],
        "purposes": ["문화교류", "언어교환"],
        # 성격 일치 최우선 (감성형)
        "weight_personality": 35, "weight_interests": 25, "weight_purpose": 20,
        "weight_language": 10, "weight_nationality": 5, "weight_major": 3, "weight_year": 2,
    },
    {
        "email": "jiho@example.com",
        "password": "test1234!",
        "name": "한지호",
        "country": "🇰🇷 대한민국",
        "college": "의생명과학대학",
        "major": "간호학과",
        "year": "1학년",
        "description": "의료 용어와 학교 생활을 같이 공부해요",
        "is_international": False,
        "interests": ["독서"],
        "personalities": ["진지한"],
        "languages": ["한국어", "영어"],
        "purposes": ["학업도움"],
        # 전공·목적 최우선 (학업 특화형)
        "weight_major": 35, "weight_purpose": 30, "weight_language": 15,
        "weight_personality": 10, "weight_interests": 5, "weight_year": 3, "weight_nationality": 2,
    },

    # Additional foreign sample users.
    {
        "email": "ethan@example.com",
        "password": "test1234!",
        "name": "Ethan",
        "country": "🇺🇸 미국",
        "college": "공과대학",
        "major": "기계공학과",
        "year": "3학년",
        "description": "운동과 여행을 좋아하는 교환학생이에요",
        "is_international": True,
        "interests": ["운동", "여행", "스포츠"],
        "personalities": ["외향적", "호기심 많은"],
        "languages": ["영어", "한국어"],
        "purposes": ["친구사귀기", "문화교류"],
        # 전 항목 균형 배분 (올라운더형)
        "weight_purpose": 20, "weight_interests": 20, "weight_personality": 20,
        "weight_language": 20, "weight_nationality": 10, "weight_major": 5, "weight_year": 5,
    },
    {
        "email": "haruto@example.com",
        "password": "test1234!",
        "name": "Haruto",
        "country": "🇯🇵 일본",
        "college": "문화예술대학",
        "major": "디자인학과",
        "year": "1학년",
        "description": "사진과 카페 탐방을 같이 하고 싶어요",
        "is_international": True,
        "interests": ["사진", "카페 탐방", "패션"],
        "personalities": ["내향적", "차분한"],
        "languages": ["일본어", "한국어"],
        "purposes": ["문화교류", "친구사귀기"],
        # 국적·언어 중시 (한국인 파트너 강선호)
        "weight_nationality": 30, "weight_language": 25, "weight_interests": 20,
        "weight_personality": 15, "weight_purpose": 5, "weight_major": 3, "weight_year": 2,
    },
    {
        "email": "liwei@example.com",
        "password": "test1234!",
        "name": "Li Wei",
        "country": "🇨🇳 중국",
        "college": "경영대학",
        "major": "경영학과",
        "year": "2학년",
        "description": "한국어 과제와 발표 연습을 같이 해요",
        "is_international": True,
        "interests": ["독서", "영화", "언어"],
        "personalities": ["계획적인", "진지한"],
        "languages": ["중국어", "한국어", "영어"],
        "purposes": ["학업도움", "언어교환"],
        # 목적·전공 중시 (학업 파트너형)
        "weight_purpose": 30, "weight_major": 25, "weight_language": 20,
        "weight_interests": 15, "weight_personality": 5, "weight_year": 3, "weight_nationality": 2,
    },
    {
        "email": "chenyu@example.com",
        "password": "test1234!",
        "name": "Chen Yu",
        "country": "🇨🇳 중국",
        "college": "IT대학",
        "major": "컴퓨터공학과",
        "year": "4학년",
        "description": "게임 개발과 알고리즘 이야기를 좋아해요",
        "is_international": True,
        "interests": ["게임", "음악", "언어"],
        "personalities": ["내향적", "호기심 많은"],
        "languages": ["중국어", "영어"],
        "purposes": ["학업도움", "친구사귀기"],
        # 전공 최우선 (기술 전문형)
        "weight_major": 35, "weight_purpose": 25, "weight_interests": 20,
        "weight_language": 10, "weight_personality": 5, "weight_year": 3, "weight_nationality": 2,
    },
    {
        "email": "linh@example.com",
        "password": "test1234!",
        "name": "Linh",
        "country": "🇻🇳 베트남",
        "college": "인문대학",
        "major": "국어국문학과",
        "year": "2학년",
        "description": "한국어 글쓰기와 드라마 이야기를 하고 싶어요",
        "is_international": True,
        "interests": ["드라마", "음악", "요리"],
        "personalities": ["친화적", "감성적인"],
        "languages": ["베트남어", "한국어"],
        "purposes": ["언어교환", "문화교류"],
        # 언어 교환 + 국적 다양성 중시
        "weight_language": 35, "weight_purpose": 25, "weight_nationality": 15,
        "weight_interests": 15, "weight_personality": 5, "weight_major": 3, "weight_year": 2,
    },
    {
        "email": "minh@example.com",
        "password": "test1234!",
        "name": "Minh",
        "country": "🇻🇳 베트남",
        "college": "사회과학대학",
        "major": "행정학과",
        "year": "3학년",
        "description": "학교 행정 절차를 같이 알아보고 싶어요",
        "is_international": True,
        "interests": ["여행", "사진", "운동"],
        "personalities": ["진지한", "계획적인"],
        "languages": ["베트남어", "영어"],
        "purposes": ["학업도움", "친구사귀기"],
        # 학년 근접 최우선 (같은 학년 파트너 선호)
        "weight_year": 35, "weight_purpose": 25, "weight_interests": 20,
        "weight_language": 10, "weight_personality": 5, "weight_major": 3, "weight_nationality": 2,
    },
    {
        "email": "claire@example.com",
        "password": "test1234!",
        "name": "Claire",
        "country": "🇫🇷 프랑스",
        "college": "문화예술대학",
        "major": "미술학과",
        "year": "2학년",
        "description": "전시와 영화 이야기를 나누고 싶어요",
        "is_international": True,
        "interests": ["영화", "패션", "언어"],
        "personalities": ["감성적인", "호기심 많은"],
        "languages": ["프랑스어", "영어", "한국어"],
        "purposes": ["문화교류", "언어교환"],
        # 관심사·언어·국적 다양성 중시 (문화 탐험가형)
        "weight_interests": 30, "weight_language": 25, "weight_nationality": 20,
        "weight_personality": 15, "weight_purpose": 5, "weight_major": 3, "weight_year": 2,
    },
]


def _validate_choice_list(name: str, values: list[str], valid: set[str], max_count: int):
    if len(values) > max_count:
        raise ValueError(f"{name}은 최대 {max_count}개까지 가능합니다: {values}")

    invalid = [value for value in values if value not in valid]
    if invalid:
        raise ValueError(f"{name}에 허용되지 않은 값이 있습니다: {invalid}")


def validate_seed_users():
    emails = set()
    for data in SEED_USERS:
        email = data["email"]
        if email in emails:
            raise ValueError(f"중복 이메일: {email}")
        emails.add(email)

        _validate_choice_list("interests", data["interests"], VALID_INTERESTS, 3)
        _validate_choice_list(
            "personalities", data["personalities"], VALID_PERSONALITIES, 3
        )
        _validate_choice_list("languages", data["languages"], VALID_LANGUAGES, 3)
        _validate_choice_list("purposes", data["purposes"], VALID_PURPOSES, 4)

        if len(data["description"]) > 40:
            raise ValueError(f"description이 40자를 초과합니다: {email}")

        is_korean = data["country"].endswith("대한민국")
        if data["is_international"] == is_korean:
            raise ValueError(f"is_international 값이 country와 맞지 않습니다: {email}")


def _replace_relations(db, user: User, data: dict):
    db.query(UserInterest).filter(UserInterest.user_id == user.id).delete(
        synchronize_session=False
    )
    db.query(UserPersonality).filter(UserPersonality.user_id == user.id).delete(
        synchronize_session=False
    )
    db.query(UserLanguage).filter(UserLanguage.user_id == user.id).delete(
        synchronize_session=False
    )
    db.query(UserExchangePurpose).filter(
        UserExchangePurpose.user_id == user.id
    ).delete(synchronize_session=False)

    for item in data["interests"]:
        db.add(UserInterest(user_id=user.id, interest=item))
    for item in data["personalities"]:
        db.add(UserPersonality(user_id=user.id, personality=item))
    for item in data["languages"]:
        db.add(UserLanguage(user_id=user.id, language=item))
    for item in data["purposes"]:
        db.add(UserExchangePurpose(user_id=user.id, purpose=item))


def seed():
    validate_seed_users()

    db = SessionLocal()
    try:
        created = 0
        updated = 0

        for data in SEED_USERS:
            user = db.query(User).filter(User.email == data["email"]).first()

            if user:
                updated += 1
            else:
                user = User(email=data["email"])
                db.add(user)
                created += 1

            user.password_hash = hash_pw(data["password"])
            user.name = data["name"]
            user.country = data["country"]
            user.college = data["college"]
            user.major = data["major"]
            user.year = data["year"]
            user.description = data["description"]
            user.is_international = data["is_international"]
            user.is_verified = True

            # 매칭 가중치 (합계=100, 없으면 기본값 유지)
            user.weight_purpose      = data.get("weight_purpose",      25)
            user.weight_interests    = data.get("weight_interests",     20)
            user.weight_language     = data.get("weight_language",      18)
            user.weight_personality  = data.get("weight_personality",   17)
            user.weight_major        = data.get("weight_major",          8)
            user.weight_year         = data.get("weight_year",           7)
            user.weight_nationality  = data.get("weight_nationality",    5)

            db.flush()
            _replace_relations(db, user, data)

            print(f"  저장됨: {data['name']} ({data['email']})")

        db.commit()
        print(f"시딩 완료! 추가 {created}명, 업데이트 {updated}명")
    except Exception as e:
        db.rollback()
        print(f"오류: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
