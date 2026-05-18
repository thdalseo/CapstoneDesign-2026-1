from datetime import date, datetime, timedelta, time

import bcrypt

from app.core.database import Base, SessionLocal, engine
from app.models.user import (
    ChatMessage,
    ChatRoom,
    EmailVerification,
    HelpHelper,
    HelpPost,
    Match,
    User,
    UserExchangePurpose,
    UserInterest,
    UserLanguage,
    UserPersonality,
)


SAMPLE_EMAILS = [
    "sofia@kangwon.ac.kr",
    "liam@kangwon.ac.kr",
    "amara@kangwon.ac.kr",
    "anna@kangwon.ac.kr",
    "honggildong@kangwon.ac.kr",
    "minji@kangwon.ac.kr",
    "jaehyun@kangwon.ac.kr",
    "seoyeon@kangwon.ac.kr",
    "liwei@kangwon.ac.kr",
    "amir@kangwon.ac.kr",
]

SAMPLE_VERIFICATION_EMAILS = [
    "pending@kangwon.ac.kr",
    "verified@kangwon.ac.kr",
]

SAMPLE_PASSWORD = "test1234"


def hash_password(password):
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def add_profile_items(session, user, interests, purposes, personalities, languages):
    session.add_all(UserInterest(user_id=user.id, interest=item) for item in interests)
    session.add_all(
        UserExchangePurpose(user_id=user.id, purpose=item) for item in purposes
    )
    session.add_all(
        UserPersonality(user_id=user.id, personality=item) for item in personalities
    )
    session.add_all(UserLanguage(user_id=user.id, language=item) for item in languages)


def delete_existing_samples(session):
    users = session.query(User).filter(User.email.in_(SAMPLE_EMAILS)).all()
    user_ids = [user.id for user in users]

    if user_ids:
        room_ids = [
            room.id
            for room in session.query(ChatRoom)
            .filter(
                (ChatRoom.user_id_a.in_(user_ids)) | (ChatRoom.user_id_b.in_(user_ids))
            )
            .all()
        ]
        post_ids = [
            post.id
            for post in session.query(HelpPost)
            .filter(HelpPost.author_id.in_(user_ids))
            .all()
        ]

        if room_ids:
            session.query(ChatMessage).filter(ChatMessage.room_id.in_(room_ids)).delete(
                synchronize_session=False
            )
        if post_ids:
            session.query(HelpHelper).filter(HelpHelper.post_id.in_(post_ids)).delete(
                synchronize_session=False
            )

        session.query(HelpHelper).filter(HelpHelper.helper_id.in_(user_ids)).delete(
            synchronize_session=False
        )
        session.query(HelpPost).filter(HelpPost.author_id.in_(user_ids)).delete(
            synchronize_session=False
        )
        session.query(ChatRoom).filter(
            (ChatRoom.user_id_a.in_(user_ids)) | (ChatRoom.user_id_b.in_(user_ids))
        ).delete(synchronize_session=False)
        session.query(Match).filter(
            (Match.user_id_a.in_(user_ids)) | (Match.user_id_b.in_(user_ids))
        ).delete(synchronize_session=False)
        session.query(UserInterest).filter(UserInterest.user_id.in_(user_ids)).delete(
            synchronize_session=False
        )
        session.query(UserExchangePurpose).filter(
            UserExchangePurpose.user_id.in_(user_ids)
        ).delete(synchronize_session=False)
        session.query(UserPersonality).filter(
            UserPersonality.user_id.in_(user_ids)
        ).delete(synchronize_session=False)
        session.query(UserLanguage).filter(UserLanguage.user_id.in_(user_ids)).delete(
            synchronize_session=False
        )
        session.query(User).filter(User.id.in_(user_ids)).delete(
            synchronize_session=False
        )

    session.query(EmailVerification).filter(
        EmailVerification.email.in_(SAMPLE_EMAILS + SAMPLE_VERIFICATION_EMAILS)
    ).delete(synchronize_session=False)
    session.commit()


def seed_users(session):
    password_hash = hash_password(SAMPLE_PASSWORD)
    users = [
        User(
            email="sofia@kangwon.ac.kr",
            password_hash=password_hash,
            name="Sofia",
            country="미국",
            college="경영대학",
            major="경영학과",
            year="2학년",
            description="한국어 공부 중이에요. 서로 편하게 언어 교환해요.",
            is_verified=True,
            is_international=True,
        ),
        User(
            email="liam@kangwon.ac.kr",
            password_hash=password_hash,
            name="Liam",
            country="영국",
            college="IT대학",
            major="컴퓨터공학과",
            year="3학년",
            description="한국 문화에 관심이 많아요. 같이 공부하고 싶어요.",
            is_verified=True,
            is_international=True,
        ),
        User(
            email="amara@kangwon.ac.kr",
            password_hash=password_hash,
            name="Amara",
            country="나이지리아",
            college="국제교류본부",
            major="국제학부",
            year="1학년",
            description="캠퍼스 생활 지원이 필요해요. 친하게 지내고 싶어요.",
            is_verified=True,
            is_international=True,
        ),
        User(
            email="anna@kangwon.ac.kr",
            password_hash=password_hash,
            name="안나",
            country="미국",
            college="경영대학",
            major="경영학과",
            year="2학년",
            description="한국어 과제와 글쓰기 도움을 받고 싶어요.",
            is_verified=True,
            is_international=True,
        ),
        User(
            email="honggildong@kangwon.ac.kr",
            password_hash=password_hash,
            name="홍길동",
            country="대한민국",
            college="IT대학",
            major="컴퓨터공학과",
            year="3학년",
            description="코딩 공부와 학교생활 도움을 줄 수 있어요.",
            is_verified=True,
            is_international=False,
        ),
        User(
            email="minji@kangwon.ac.kr",
            password_hash=password_hash,
            name="김민지",
            country="대한민국",
            college="인문대학",
            major="영어영문학과",
            year="4학년",
            description="영어와 한국어 대화를 도와줄 수 있어요.",
            is_verified=True,
            is_international=False,
        ),
        User(
            email="liwei@kangwon.ac.kr",
            password_hash=password_hash,
            name="Li Wei",
            country="중국",
            college="경영대학",
            major="경영학과",
            year="3학년",
            description="수업 과제와 한국어 회화 도움을 받고 싶어요.",
            is_verified=True,
            is_international=True,
        ),
        User(
            email="amir@kangwon.ac.kr",
            password_hash=password_hash,
            name="Amir Khan",
            country="우즈베키스탄",
            college="사회과학대학",
            major="행정학과",
            year="1학년",
            description="병원, 은행, 행정 업무를 같이 해줄 친구를 찾고 있어요.",
            is_verified=True,
            is_international=True,
        ),
    ]
    session.add_all(users)
    session.flush()

    by_email = {user.email: user for user in users}
    add_profile_items(
        session,
        by_email["sofia@kangwon.ac.kr"],
        interests=["여행", "카페 탐방", "영화"],
        purposes=["언어교환", "문화교류"],
        personalities=["친절함", "긍정적"],
        languages=["한국어", "영어"],
    )
    add_profile_items(
        session,
        by_email["liam@kangwon.ac.kr"],
        interests=["게임", "음악", "K-POP"],
        purposes=["언어교환", "친구사귀기"],
        personalities=["활발함", "사교적"],
        languages=["영어", "한국어"],
    )
    add_profile_items(
        session,
        by_email["amara@kangwon.ac.kr"],
        interests=["요리", "운동", "사진"],
        purposes=["문화교류", "학업도움"],
        personalities=["사교적", "성실함"],
        languages=["영어", "한국어"],
    )
    add_profile_items(
        session,
        by_email["anna@kangwon.ac.kr"],
        interests=["언어", "독서", "영화"],
        purposes=["학업도움", "언어교환"],
        personalities=["차분함", "꼼꼼함"],
        languages=["영어", "한국어"],
    )
    add_profile_items(
        session,
        by_email["honggildong@kangwon.ac.kr"],
        interests=["게임", "음악", "K-POP"],
        purposes=["학업도움", "친구사귀기"],
        personalities=["계획적", "친절함"],
        languages=["한국어", "영어"],
    )
    add_profile_items(
        session,
        by_email["minji@kangwon.ac.kr"],
        interests=["여행", "카페 탐방", "영화", "언어"],
        purposes=["언어교환", "문화교류"],
        personalities=["활발함", "친절함"],
        languages=["한국어", "영어"],
    )
    add_profile_items(
        session,
        by_email["liwei@kangwon.ac.kr"],
        interests=["요리", "사진", "게임", "카페"],
        purposes=["학업도움", "친구사귀기"],
        personalities=["차분함", "성실함"],
        languages=["중국어", "한국어"],
    )
    add_profile_items(
        session,
        by_email["amir@kangwon.ac.kr"],
        interests=["스포츠", "여행", "드라마", "언어"],
        purposes=["문화교류", "학업도움"],
        personalities=["사교적", "성실함"],
        languages=["러시아어", "영어", "한국어"],
    )
    return by_email


def seed_matches(session, users):
    session.add_all(
        [
            Match(
                user_id_a=users["minji@kangwon.ac.kr"].id,
                user_id_b=users["sofia@kangwon.ac.kr"].id,
                match_score=92,
            ),
            Match(
                user_id_a=users["honggildong@kangwon.ac.kr"].id,
                user_id_b=users["liam@kangwon.ac.kr"].id,
                match_score=87,
            ),
            Match(
                user_id_a=users["minji@kangwon.ac.kr"].id,
                user_id_b=users["amara@kangwon.ac.kr"].id,
                match_score=81,
            ),
            Match(
                user_id_a=users["minji@kangwon.ac.kr"].id,
                user_id_b=users["anna@kangwon.ac.kr"].id,
                match_score=76,
            ),
        ]
    )


def seed_chat(session, users):
    room = ChatRoom(
        user_id_a=users["minji@kangwon.ac.kr"].id,
        user_id_b=users["sofia@kangwon.ac.kr"].id,
    )
    session.add(room)
    session.flush()
    session.add_all(
        [
            ChatMessage(
                room_id=room.id,
                sender_id=None,
                content="매칭이 성사되었습니다. 첫 인사를 나눠보세요.",
                is_system=True,
            ),
            ChatMessage(
                room_id=room.id,
                sender_id=users["sofia@kangwon.ac.kr"].id,
                content="안녕하세요! 한국어 공부하면서 카페도 같이 가고 싶어요.",
            ),
            ChatMessage(
                room_id=room.id,
                sender_id=users["minji@kangwon.ac.kr"].id,
                content="좋아요. 학교 근처 조용한 카페에서 언어 교환해요.",
            ),
        ]
    )


def seed_help_posts(session, users):
    today = date.today()
    posts = [
        HelpPost(
            author_id=users["anna@kangwon.ac.kr"].id,
            category="언어",
            title="한국어 과제 피드백 부탁드려요!",
            place="도서관 1층",
            date=today + timedelta(days=1),
            time=time(14, 0),
            memo="한국어 글쓰기 교정과 문법 확인이 필요해요.",
            is_urgent=False,
        ),
        HelpPost(
            author_id=users["honggildong@kangwon.ac.kr"].id,
            category="수업",
            title="코딩 공부 같이해요!",
            place="중앙도서관",
            date=today + timedelta(days=2),
            time=time(10, 0),
            memo="시험 준비 같이 할 스터디 구해요.",
            is_urgent=True,
        ),
        HelpPost(
            author_id=users["sofia@kangwon.ac.kr"].id,
            category="생활",
            title="기숙사 근처 마트 같이 가주실 분",
            place="강원대 정문",
            date=today + timedelta(days=3),
            time=time(16, 30),
            memo="생필품을 어디서 사면 좋은지 알고 싶어요.",
            is_urgent=False,
        ),
        HelpPost(
            author_id=users["liam@kangwon.ac.kr"].id,
            category="언어",
            title="한국어 회화 연습 파트너 구해요",
            place="학생회관",
            date=today + timedelta(days=4),
            time=time(18, 0),
            memo="일상 대화를 자연스럽게 연습하고 싶어요.",
            is_urgent=False,
        ),
        HelpPost(
            author_id=users["amara@kangwon.ac.kr"].id,
            category="행정",
            title="학생증 재발급 절차 도움",
            place="학사지원과",
            date=today + timedelta(days=5),
            time=time(11, 30),
            memo="필요 서류와 신청 절차를 같이 확인하고 싶어요.",
            is_urgent=False,
        ),
    ]
    session.add_all(posts)
    session.flush()

    session.add_all(
        [
            HelpHelper(
                post_id=posts[0].id, helper_id=users["minji@kangwon.ac.kr"].id
            ),
            HelpHelper(
                post_id=posts[1].id, helper_id=users["liam@kangwon.ac.kr"].id
            ),
            HelpHelper(
                post_id=posts[2].id, helper_id=users["honggildong@kangwon.ac.kr"].id
            ),
            HelpHelper(
                post_id=posts[3].id, helper_id=users["minji@kangwon.ac.kr"].id
            ),
        ]
    )


def seed_email_verifications(session):
    now = datetime.utcnow()
    session.add_all(
        [
            EmailVerification(
                email="pending@kangwon.ac.kr",
                code="123456",
                expires_at=now + timedelta(minutes=30),
                is_verified=False,
            ),
            EmailVerification(
                email="verified@kangwon.ac.kr",
                code="654321",
                expires_at=now + timedelta(minutes=30),
                is_verified=True,
            ),
        ]
    )


def main():
    Base.metadata.create_all(bind=engine)
    session = SessionLocal()
    try:
        delete_existing_samples(session)
        users = seed_users(session)
        seed_matches(session, users)
        seed_chat(session, users)
        seed_help_posts(session, users)
        seed_email_verifications(session)
        session.commit()

        print("[OK] Seed data inserted.")
        print(f"  sample password: {SAMPLE_PASSWORD}")
        print(f"  users: {session.query(User).count()}")
        print(f"  matches: {session.query(Match).count()}")
        print(f"  chat_rooms: {session.query(ChatRoom).count()}")
        print(f"  chat_messages: {session.query(ChatMessage).count()}")
        print(f"  help_posts: {session.query(HelpPost).count()}")
        print(f"  help_helpers: {session.query(HelpHelper).count()}")
        print(f"  email_verifications: {session.query(EmailVerification).count()}")
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


if __name__ == "__main__":
    main()
