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
