import json
import os
from typing import Dict, List

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import ChatMessage, ChatRoom, User

router = APIRouter(tags=["chat"])


# ── WebSocket 연결 관리 ───────────────────────────────────────────────────────

class _ConnectionManager:
    def __init__(self):
        self.active: Dict[int, List[WebSocket]] = {}

    async def connect(self, room_id: int, ws: WebSocket):
        await ws.accept()
        self.active.setdefault(room_id, []).append(ws)

    def disconnect(self, room_id: int, ws: WebSocket):
        room = self.active.get(room_id, [])
        if ws in room:
            room.remove(ws)

    async def broadcast(self, room_id: int, data: dict, exclude: WebSocket | None = None):
        for ws in list(self.active.get(room_id, [])):
            if ws is exclude:
                continue
            try:
                await ws.send_json(data)
            except Exception:
                pass


manager = _ConnectionManager()


# ── 스키마 ────────────────────────────────────────────────────────────────────

class CreateRoomRequest(BaseModel):
    user_id_a: int
    user_id_b: int


class IcebreakingRequest(BaseModel):
    # 내 정보
    my_name: str
    my_country: str
    my_major: str
    my_interests: List[str] = []
    my_purposes: List[str] = []
    my_personalities: List[str] = []
    # 상대방 정보
    other_name: str
    other_country: str
    other_major: str
    other_interests: List[str] = []
    # 앱 언어 코드 (ko/en/zh/vi/ja)
    locale: str = "ko"


# ── REST 엔드포인트 ───────────────────────────────────────────────────────────

@router.post("/chat/rooms")
def get_or_create_room(req: CreateRoomRequest, db: Session = Depends(get_db)):
    """두 유저 사이의 채팅방을 찾거나 생성한다. user_id 가 작은 쪽이 항상 user_id_a."""
    a, b = sorted([req.user_id_a, req.user_id_b])

    room = (
        db.query(ChatRoom)
        .filter(ChatRoom.user_id_a == a, ChatRoom.user_id_b == b)
        .first()
    )
    if not room:
        for uid in [a, b]:
            if not db.query(User).filter(User.id == uid).first():
                raise HTTPException(status_code=404, detail=f"유저 {uid}를 찾을 수 없습니다.")
        room = ChatRoom(user_id_a=a, user_id_b=b)
        db.add(room)
        db.commit()
        db.refresh(room)

    return {"room_id": room.id}


@router.get("/chat/rooms")
def get_user_rooms(user_id: int, db: Session = Depends(get_db)):
    """내가 참여한 채팅방 목록 (마지막 메시지 포함). 최신 순 정렬."""
    rooms = (
        db.query(ChatRoom)
        .filter(or_(ChatRoom.user_id_a == user_id, ChatRoom.user_id_b == user_id))
        .order_by(ChatRoom.created_at.desc())
        .all()
    )
    result = []
    for room in rooms:
        other_id = room.user_id_b if room.user_id_a == user_id else room.user_id_a
        other = db.query(User).filter(User.id == other_id).first()
        if not other:
            continue
        last_msg = (
            db.query(ChatMessage)
            .filter(ChatMessage.room_id == room.id)
            .order_by(ChatMessage.created_at.desc())
            .first()
        )
        # "🇺🇸 미국" → "🇺🇸" (국기 이모지만 추출)
        country_parts = (other.country or "").split()
        country_flag = country_parts[0] if country_parts else ""

        result.append({
            "room_id": room.id,
            "other_user_id": str(other.id),
            "other_user_name": other.name,
            "other_user_country": country_flag,
            "other_user_major": other.major or "",
            "other_user_year": other.year or "",
            "last_message": last_msg.content if last_msg else None,
            "last_message_time": last_msg.created_at.isoformat() if last_msg else None,
        })
    return result


@router.get("/chat/rooms/{room_id}/messages")
def get_messages(room_id: int, limit: int = 50, db: Session = Depends(get_db)):
    """채팅방의 최근 메시지(오래된 순)를 반환한다."""
    msgs = (
        db.query(ChatMessage)
        .filter(ChatMessage.room_id == room_id)
        .order_by(ChatMessage.created_at.asc())
        .limit(limit)
        .all()
    )
    return [
        {
            "id": m.id,
            "sender_id": m.sender_id,
            "content": m.content,
            "timestamp": m.created_at.isoformat(),
            "is_system": m.is_system,
        }
        for m in msgs
    ]


# ── AI 아이스브레이킹 ─────────────────────────────────────────────────────────

# 언어코드 → 언어명 (프롬프트용)
_LOCALE_NAMES = {
    "ko": "한국어",
    "en": "English",
    "zh": "中文",
    "vi": "Tiếng Việt",
    "ja": "日本語",
}

# 기본 fallback 질문 (언어별)
_FALLBACK: dict[str, list[str]] = {
    "ko": [
        "서로 공통 관심사가 있는 것 같은데, 어떻게 시작하게 됐어요?",
        "한국에서 가장 인상 깊었던 음식이나 장소가 있었나요?",
        "언어 공부할 때 어떤 방법이 제일 효과적이었어요?",
        "주말에 주로 어떻게 시간을 보내요?",
    ],
    "en": [
        "It looks like we share some interests — how did you get into them?",
        "What's been the most memorable food or place you've tried in Korea?",
        "What's the most effective way you've found to study a language?",
        "What do you usually do on weekends?",
    ],
    "zh": [
        "我们好像有共同兴趣，你是怎么开始的呢？",
        "在韩国最让你印象深刻的食物或地方是什么？",
        "你觉得学语言最有效的方法是什么？",
        "周末通常怎么度过？",
    ],
    "vi": [
        "Có vẻ chúng ta có chung sở thích — bạn bắt đầu như thế nào?",
        "Món ăn hoặc địa điểm nào ở Hàn Quốc khiến bạn ấn tượng nhất?",
        "Bạn thấy cách nào học ngôn ngữ hiệu quả nhất?",
        "Cuối tuần bạn thường làm gì?",
    ],
    "ja": [
        "共通の趣味がありそうですね。きっかけは何でしたか？",
        "韓国で一番印象に残った食べ物や場所はありますか？",
        "語学学習で一番効果的だと思う方法は何ですか？",
        "週末はどんなふうに過ごしていますか？",
    ],
}


def _build_prompt(req: IcebreakingRequest, lang_name: str) -> str:
    my_info = (
        f"이름: {req.my_name}, 국적: {req.my_country}, 전공: {req.my_major}, "
        f"관심사: {', '.join(req.my_interests) or '없음'}, "
        f"교류목적: {', '.join(req.my_purposes) or '없음'}, "
        f"성향: {', '.join(req.my_personalities) or '없음'}"
    )
    other_info = (
        f"이름: {req.other_name}, 국적: {req.other_country}, 전공: {req.other_major}, "
        f"관심사: {', '.join(req.other_interests) or '없음'}"
    )
    return f"""두 사람이 처음 대화를 시작합니다. 자연스러운 대화 시작 질문 4개를 만들어주세요.

[사용자 A]
{my_info}

[사용자 B]
{other_info}

조건:
- 두 사람의 공통점이나 서로 보완되는 부분을 활용할 것
- 짧고 자연스러운 구어체
- 너무 개인적이거나 민감한 질문 제외
- 반드시 {lang_name}로 작성
- JSON 형식만 반환: {{"questions": ["질문1", "질문2", "질문3", "질문4"]}}"""


async def _call_groq(prompt: str, api_key: str) -> list[str]:
    from openai import OpenAI
    client = OpenAI(
        api_key=api_key,
        base_url="https://api.groq.com/openai/v1",
    )
    response = client.chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.8,
        max_tokens=400,
    )
    data = json.loads(response.choices[0].message.content)
    return data.get("questions", [])


async def _call_openai(prompt: str, api_key: str) -> list[str]:
    from openai import OpenAI
    client = OpenAI(api_key=api_key)
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.8,
        max_tokens=400,
    )
    data = json.loads(response.choices[0].message.content)
    return data.get("questions", [])


@router.post("/chat/icebreaking")
async def get_icebreaking_questions(req: IcebreakingRequest):
    """두 유저 프로필을 바탕으로 AI 아이스브레이킹 질문 4개를 생성한다.
    Groq → OpenAI → fallback 순으로 시도한다."""

    locale = req.locale if req.locale in _LOCALE_NAMES else "ko"
    lang_name = _LOCALE_NAMES[locale]
    fallback = _FALLBACK.get(locale, _FALLBACK["ko"])

    groq_key   = os.getenv("GROQ_API_KEY",   "").strip()
    openai_key = os.getenv("OPENAI_API_KEY", "").strip()

    if not groq_key and not openai_key:
        return {"questions": fallback}

    prompt = _build_prompt(req, lang_name)

    # 1순위: Groq (무료)
    if groq_key:
        try:
            questions = await _call_groq(prompt, groq_key)
            if questions:
                return {"questions": questions}
        except Exception as e:
            print(f"[icebreaking] Groq 실패: {e}")

    # 2순위: OpenAI
    if openai_key:
        try:
            questions = await _call_openai(prompt, openai_key)
            if questions:
                return {"questions": questions}
        except Exception as e:
            print(f"[icebreaking] OpenAI 실패: {e}")

    return {"questions": fallback}


# ── WebSocket ─────────────────────────────────────────────────────────────────

@router.websocket("/ws/chat/{room_id}")
async def websocket_chat(
    room_id: int,
    ws: WebSocket,
    db: Session = Depends(get_db),
):
    """실시간 채팅 WebSocket 엔드포인트.

    클라이언트 → 서버 메시지 형식:
        {"type": "message", "sender_id": 1, "content": "Hello!"}

    서버 → 클라이언트 브로드캐스트 형식:
        {"type": "message", "id": 5, "sender_id": 1, "content": "Hello!", "timestamp": "..."}
    """
    await manager.connect(room_id, ws)
    try:
        while True:
            try:
                data = await ws.receive_json()
            except Exception:
                break  # 연결 종료 또는 잘못된 JSON

            if data.get("type") != "message":
                continue

            content = (data.get("content") or "").strip()
            sender_id = data.get("sender_id")
            if not content:
                continue

            # DB 저장
            msg = ChatMessage(
                room_id=room_id,
                sender_id=int(sender_id) if sender_id is not None else None,
                content=content,
                is_system=False,
            )
            db.add(msg)
            db.commit()
            db.refresh(msg)

            # 보낸 사람을 제외한 나머지에게 브로드캐스트
            # (보낸 사람은 낙관적 업데이트로 이미 UI에 표시됨)
            await manager.broadcast(
                room_id,
                {
                    "type": "message",
                    "id": msg.id,
                    "sender_id": msg.sender_id,
                    "content": msg.content,
                    "timestamp": msg.created_at.isoformat(),
                    "is_system": False,
                },
                exclude=ws,
            )

    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(room_id, ws)
