"""
샘플 데이터 시딩 스크립트
실행: python seed_data.py  (backend/ 디렉터리에서)

Flutter match_service.dart 의 _mockMatches 와 같은 순서의 유저를 DB에 삽입/갱신합니다.
테스트 계정 공통 비밀번호: test1234!
"""

import bcrypt
import datetime

from app.core.database import SessionLocal
from app.models.user import (
    HelpPost,
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


# ── 게시판 샘플 데이터 ─────────────────────────────────────────────────────────
# (author_email, category, title, place, date, time, memo, is_urgent)
SEED_POSTS = [
    # ── 생활 ──────────────────────────────────────────────────────────────────
    # Amara (나이지리아 → 영어)
    (
        "amara@example.com", "생활",
        "Can someone show me how to use the dormitory laundry?",
        "글로벌인재관 1층",
        datetime.date(2026, 6, 3), datetime.time(14, 0),
        "I don't know how to charge the laundry card or use the coin washing machines. Could someone come with me and explain?",
        True,
    ),
    # Linh (베트남 → 베트남어)
    (
        "linh@example.com", "생활",
        "Ai có thể cùng tôi đi siêu thị gần trường không?",
        "학생회관 정문",
        datetime.date(2026, 6, 5), datetime.time(16, 30),
        "Tôi chưa biết cách đi xe buýt đến Emart hay Homeplus. Mong có người cùng đi và hướng dẫn cho tôi!",
        False,
    ),
    # Minh (베트남 → 영어)
    (
        "minh@example.com", "생활",
        "Need help with T-money card top-up and bus transfers",
        "학생회관 앞 버스정류장",
        datetime.date(2026, 6, 4), datetime.time(9, 0),
        "I'm not sure where to recharge my transportation card or how bus transfers work in Korea. Any help is appreciated!",
        False,
    ),

    # ── 수업 ──────────────────────────────────────────────────────────────────
    # Liam (영국 → 영어)
    (
        "liam@example.com", "수업",
        "Looking for help with Data Structures assignment",
        "제1공학관 304호",
        datetime.date(2026, 6, 6), datetime.time(15, 0),
        "I have a tree and graph implementation assignment and I'm struggling to follow the Korean instructions. Could anyone explain it to me in English or Korean slowly?",
        True,
    ),
    # Chen Yu (중국 → 중국어)
    (
        "chenyu@example.com", "수업",
        "期末考试算法一起复习吧！",
        "중앙도서관 3층 스터디룸",
        datetime.date(2026, 6, 10), datetime.time(13, 0),
        "考试范围主要是动态规划和图搜索，想找2到3人一起整理笔记。欢迎任何人参加！",
        False,
    ),
    # Li Wei (중국 → 중국어)
    (
        "liwei@example.com", "수업",
        "经营统计学课听不懂，有人能帮忙解释吗？",
        "경영관 201호",
        datetime.date(2026, 6, 7), datetime.time(11, 0),
        "教授用韩语讲课，我很难跟上。下课后能花30分钟给我用中文或英文解释一下吗？",
        False,
    ),

    # ── 언어 ──────────────────────────────────────────────────────────────────
    # Sofia (미국 → 영어)
    (
        "sofia@example.com", "언어",
        "Looking for a Korean conversation partner!",
        "학생회관 카페",
        datetime.date(2026, 6, 4), datetime.time(14, 0),
        "I'd love to do a language exchange — I'll help with English and you help me with Korean. Twice a week, about an hour each session. Let's chat!",
        False,
    ),
    # Yuki (일본 → 일본어)
    (
        "yuki@example.com", "언어",
        "日本語と韓国語の言語交換パートナーを募集しています",
        "인문사회과학관 102호",
        datetime.date(2026, 6, 8), datetime.time(15, 30),
        "日本語はN2レベルです。韓国語を教えてもらいながら、日本語を一緒に練習しませんか？",
        False,
    ),
    # Claire (프랑스 → 프랑스어)
    (
        "claire@example.com", "언어",
        "J'enseigne le français en échange d'aide en coréen !",
        "미래관 세미나실",
        datetime.date(2026, 6, 11), datetime.time(16, 0),
        "Je peux vous apprendre le français jusqu'au niveau A2. En échange, j'ai besoin d'aide pour pratiquer le coréen au quotidien.",
        False,
    ),

    # ── 의료 ──────────────────────────────────────────────────────────────────
    # Marco (이탈리아 → 영어)
    (
        "marco@example.com", "의료",
        "Urgent! Need interpreter at school clinic",
        "의생명과학관 1층 학생의원",
        datetime.date(2026, 6, 2), datetime.time(10, 0),
        "I have a bad stomachache and need to see a doctor right away, but I can't explain my symptoms in Korean. Please help me urgently!",
        True,
    ),
    # Ethan (미국 → 영어)
    (
        "ethan@example.com", "의료",
        "Need help buying cold medicine at the pharmacy",
        "정문 앞 약국",
        datetime.date(2026, 6, 3), datetime.time(13, 0),
        "I have cold symptoms but can't communicate with the pharmacist. Could someone help me explain my symptoms and find the right medicine?",
        False,
    ),

    # ── 캠퍼스 ────────────────────────────────────────────────────────────────
    # Haruto (일본 → 일본어)
    (
        "haruto@example.com", "캠퍼스",
        "履修登録のシステムの使い方を教えてください",
        "미래관 로비",
        datetime.date(2026, 6, 9), datetime.time(10, 0),
        "履修登録の時期が近づいていますが、ポータルの使い方がわかりません。一緒に画面を見ながら説明していただけますか？",
        True,
    ),
    # Amara (나이지리아 → 영어)
    (
        "amara@example.com", "캠퍼스",
        "Can someone help me get my student ID card?",
        "글로벌인재관 행정실",
        datetime.date(2026, 6, 4), datetime.time(11, 30),
        "I still don't have my student ID. I'm not sure where to apply or what documents I need. Could someone guide me through the process?",
        False,
    ),
    # Linh (베트남 → 베트남어)
    (
        "linh@example.com", "캠퍼스",
        "Nhờ hướng dẫn cách đặt chỗ thư viện qua app",
        "중앙도서관 안내데스크",
        datetime.date(2026, 6, 5), datetime.time(9, 30),
        "Tôi đã cài app đặt chỗ thư viện nhưng toàn tiếng Hàn nên không biết dùng. Nhờ ai đó hướng dẫn một lần là được!",
        False,
    ),

    # ── 행정 ──────────────────────────────────────────────────────────────────
    # Linh (베트남 → 베트남어)
    (
        "linh@example.com", "행정",
        "Cần giúp đỡ gia hạn thẻ đăng ký người nước ngoài (gấp!)",
        "산학협력관 1층",
        datetime.date(2026, 6, 2), datetime.time(9, 0),
        "Thẻ của tôi còn 2 tuần nữa là hết hạn. Tôi không biết chuẩn bị giấy tờ gì. Có ai cùng đi cục xuất nhập cảnh với tôi không?",
        True,
    ),
    # Li Wei (중국 → 중국어)
    (
        "liwei@example.com", "행정",
        "怎么在网上申请成绩证明书和在校证明书？",
        "행정관 종합민원실",
        datetime.date(2026, 6, 6), datetime.time(14, 0),
        "我不知道怎么在学校门户网站上申请证明文件，也不知道打印机在哪里。能帮我一下吗？",
        False,
    ),
    # Minh (베트남 → 영어)
    (
        "minh@example.com", "행정",
        "Looking for help with D-2 visa extension documents",
        "미래관 국제교류팀",
        datetime.date(2026, 6, 12), datetime.time(10, 30),
        "I need to extend my D-2 student visa but don't know the required documents or the submission process. Anyone who has done this before, please help!",
        False,
    ),
]


def seed_help_posts():
    db = SessionLocal()
    try:
        # 기존 샘플 게시글 모두 초기화 후 재삽입
        existing_emails = {d["email"] for d in SEED_USERS}
        users = {
            u.email: u
            for u in db.query(User).filter(User.email.in_(existing_emails)).all()
        }

        # 샘플 유저가 작성한 게시글만 삭제
        for user in users.values():
            db.query(HelpPost).filter(HelpPost.author_id == user.id).delete(
                synchronize_session=False
            )
        db.flush()

        count = 0
        for (email, category, title, place, date, time, memo, is_urgent) in SEED_POSTS:
            author = users.get(email)
            if not author:
                print(f"  ⚠️ 유저 없음: {email}")
                continue
            db.add(HelpPost(
                author_id=author.id,
                category=category,
                title=title,
                place=place,
                date=date,
                time=time,
                memo=memo,
                is_urgent=is_urgent,
            ))
            count += 1

        db.commit()
        print(f"게시글 시딩 완료! {count}개 추가")
    except Exception as e:
        db.rollback()
        print(f"오류: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
    seed_help_posts()
