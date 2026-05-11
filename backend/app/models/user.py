from sqlalchemy import Boolean, Column, Integer, String, Text, DateTime
from datetime import datetime
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
    year = Column(String(20), nullable=False)
    description = Column(Text, nullable=True)
    avatar_url = Column(String(255), nullable=True)
    is_international = Column(Boolean, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class EmailVerification(Base):
    __tablename__ = "email_verifications"
    email = Column(String(100), primary_key=True, index=True)
    code = Column(String(6), nullable=False)
    expires_at = Column(DateTime, nullable=False)