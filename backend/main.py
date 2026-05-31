import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.database import Base, engine
from app.core.profanity_filter import start_auto_refresh
from app.models import user as _user_models  # noqa: F401 — 모델 등록
from app.routers import auth, chat, help_posts, translation

# 서버 시작 시 모델 기준으로 테이블 자동 생성 (없는 테이블만 생성)
Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 서버 시작: 금칙어 로드 + 24시간 자동 갱신
    asyncio.create_task(start_auto_refresh())
    yield
    # 서버 종료 시 추가 정리 필요 없음


app = FastAPI(title="Bridge API", lifespan=lifespan)

# Flutter(로컬 개발) → FastAPI 요청 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(help_posts.router)
app.include_router(chat.router)
app.include_router(translation.router)
