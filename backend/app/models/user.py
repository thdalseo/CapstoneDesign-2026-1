from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Column,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    Time,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String(100), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)

    name = Column(String(50), nullable=False)
    country = Column(String(50), nullable=False)
    college = Column(String(100), nullable=False)
    major = Column(String(100), nullable=False)
    year = Column(String(20), nullable=True)

    description = Column(Text, nullable=True)
    avatar_url = Column(String(255), nullable=True)
    is_verified = Column(Boolean, nullable=False, default=False)
    is_international = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    interests = relationship(
        "UserInterest", back_populates="user", cascade="all, delete-orphan"
    )
    exchange_purposes = relationship(
        "UserExchangePurpose", back_populates="user", cascade="all, delete-orphan"
    )
    personalities = relationship(
        "UserPersonality", back_populates="user", cascade="all, delete-orphan"
    )
    languages = relationship(
        "UserLanguage", back_populates="user", cascade="all, delete-orphan"
    )


class UserInterest(Base):
    __tablename__ = "user_interests"

    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    interest = Column(String(50), primary_key=True)

    user = relationship("User", back_populates="interests")


class UserExchangePurpose(Base):
    __tablename__ = "user_exchange_purposes"

    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    purpose = Column(
        Enum(
            "언어교환",
            "학업도움",
            "친구사귀기",
            "문화교류",
            name="purpose_enum",
            native_enum=False,
        ),
        primary_key=True,
    )

    user = relationship("User", back_populates="exchange_purposes")


class UserPersonality(Base):
    __tablename__ = "user_personalities"

    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    personality = Column(String(50), primary_key=True)

    user = relationship("User", back_populates="personalities")


class UserLanguage(Base):
    __tablename__ = "user_languages"

    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    language = Column(String(50), primary_key=True)

    user = relationship("User", back_populates="languages")


class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id_a = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    user_id_b = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    match_score = Column(Integer, nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user_a = relationship("User", foreign_keys=[user_id_a])
    user_b = relationship("User", foreign_keys=[user_id_b])

    __table_args__ = (
        UniqueConstraint("user_id_a", "user_id_b", name="uq_match_user_pair"),
        CheckConstraint("user_id_a != user_id_b", name="ck_match_not_same_user"),
        CheckConstraint(
            "match_score >= 0 AND match_score <= 100", name="ck_match_score_range"
        ),
    )


class ChatRoom(Base):
    __tablename__ = "chat_rooms"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id_a = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    user_id_b = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user_a = relationship("User", foreign_keys=[user_id_a])
    user_b = relationship("User", foreign_keys=[user_id_b])
    messages = relationship(
        "ChatMessage", back_populates="room", cascade="all, delete-orphan"
    )

    __table_args__ = (
        UniqueConstraint("user_id_a", "user_id_b", name="uq_chat_room_user_pair"),
        CheckConstraint("user_id_a != user_id_b", name="ck_chat_room_not_same_user"),
    )


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    room_id = Column(
        Integer, ForeignKey("chat_rooms.id", ondelete="CASCADE"), nullable=False
    )
    sender_id = Column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    content = Column(Text, nullable=False)
    is_system = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    room = relationship("ChatRoom", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id])


class HelpPost(Base):
    __tablename__ = "help_posts"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    author_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    category = Column(
        Enum(
            "생활",
            "수업",
            "언어",
            "의료",
            "캠퍼스",
            "행정",
            name="category_enum",
            native_enum=False,
        ),
        nullable=False,
    )
    title = Column(String(200), nullable=False)
    place = Column(String(200), nullable=False)
    date = Column(Date, nullable=False)
    time = Column(Time, nullable=False)
    memo = Column(Text, nullable=True)

    is_urgent = Column(Boolean, nullable=False, default=False)
    is_completed = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    author = relationship("User", foreign_keys=[author_id])
    helpers = relationship(
        "HelpHelper", back_populates="post", cascade="all, delete-orphan"
    )


class HelpHelper(Base):
    __tablename__ = "help_helpers"

    post_id = Column(
        Integer, ForeignKey("help_posts.id", ondelete="CASCADE"), primary_key=True
    )
    helper_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    post = relationship("HelpPost", back_populates="helpers")
    helper = relationship("User", foreign_keys=[helper_id])


class EmailVerification(Base):
    __tablename__ = "email_verifications"

    email = Column(String(100), primary_key=True, index=True)
    code = Column(String(6), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    is_verified = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
