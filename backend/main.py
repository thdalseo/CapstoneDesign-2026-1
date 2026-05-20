from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth, chat, help_posts

app = FastAPI(title="Bridge API")

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
