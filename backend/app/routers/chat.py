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
    # 매칭 가중치 (합계 = 100, 기본값은 균등 배분)
    weight_major: int = 17
    weight_interests: int = 17
    weight_personality: int = 17
    weight_language: int = 17
    weight_purpose: int = 17
    weight_nationality: int = 15
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

# 기본 fallback 질문 (언어별, 1인칭 시점)
_FALLBACK: dict[str, list[str]] = {
    "ko": [
        "저도 여행을 정말 좋아하는데, 혹시 가장 기억에 남는 여행지가 있어요?",
        "한국 오고 나서 가장 인상 깊었던 음식이나 장소가 있었나요?",
        "저는 언어 공부할 때 드라마를 많이 보는 편인데, 어떤 방법이 효과적이었어요?",
        "주말에 주로 어떻게 시간을 보내요?",
    ],
    "en": [
        "I love traveling too — do you have a favorite destination you'd recommend?",
        "I'm curious, what's the most memorable food or place you've found in Korea?",
        "I usually watch dramas to study languages — what's worked best for you?",
        "What do you usually do on weekends?",
    ],
    "zh": [
        "我也很喜欢旅行，你有没有最难忘的旅行地点？",
        "来韩国之后，有没有让你印象最深的食物或地方？",
        "我学语言的时候喜欢看剧，你觉得什么方法最有效？",
        "周末你通常怎么度过？",
    ],
    "vi": [
        "Tôi cũng rất thích du lịch, bạn có địa điểm nào đáng nhớ nhất không?",
        "Từ khi đến Hàn Quốc, bạn ấn tượng nhất với món ăn hay địa điểm nào?",
        "Tôi hay xem phim để học ngôn ngữ, bạn thấy cách nào hiệu quả nhất?",
        "Cuối tuần bạn thường làm gì?",
    ],
    "ja": [
        "私も旅行が大好きなんですが、一番印象に残った場所はどこですか？",
        "韓国に来てから、一番印象に残った食べ物や場所はありますか？",
        "私はドラマを見て語学を勉強しているんですが、どんな方法が効果的でしたか？",
        "週末はどんなふうに過ごしていますか？",
    ],
}


_PROMPT_TEMPLATE = {
    "ko": """\
사용자 A가 사용자 B에게 처음으로 말을 거는 상황입니다.
사용자 A 입장에서 B에게 직접 건네는 자연스러운 첫 마디 질문 4개를 한국어로 만들어주세요.

[사용자 A]
{my_info}

[사용자 B]
{other_info}

조건:
- 질문만 작성할 것. 사족·겸손 표현·자기소개 절대 금지 (예: "저는 잘 모르지만", "아는 게 별로 없는데" 등)
- "두 분", "서로", "두 사람" 같은 외부 시점 표현 금지
- 이름 뒤 호칭("씨" 등) 붙이지 말 것
- 1인칭("저도", "저는")은 필요할 때만 자연스럽게 — 모든 문장에 억지로 넣지 말 것
- B의 관심사나 두 사람의 공통점을 소재로 활용
- {priority}
- 짧고 가볍게 말 트는 구어체
- JSON만 반환: {{"questions": ["질문1", "질문2", "질문3", "질문4"]}}""",

    "en": """\
User A is starting a conversation with User B for the first time.
Write 4 natural opening questions in English that User A would say directly to User B.

[User A]
{my_info}

[User B]
{other_info}

Rules:
- Questions only. No filler, self-deprecation, or unnecessary context (e.g. "I don't know much about it, but...")
- Never use third-person phrases like "you both", "the two of you"
- No honorifics or titles after names
- Use first person ("I", "I also") only when it feels natural — don't force it into every sentence
- Base questions on B's interests or shared traits
- {priority}
- Keep it short and casual (first meeting)
- Return JSON only: {{"questions": ["q1", "q2", "q3", "q4"]}}""",

    "zh": """\
用户A第一次和用户B开始对话。
请用中文写出用户A直接对用户B说的4个自然开场问题。

[用户A]
{my_info}

[用户B]
{other_info}

要求：
- 只写问题，禁止添加多余说明、自谦表达（如"我不太了解，但是…"）
- 禁止使用"你们两个"、"你们都"等第三方视角表达
- 名字后面不加称呼语
- 第一人称（"我也"、"我"）只在自然时使用，不要每句都加
- 以B的兴趣或共同点为话题
- {priority}
- 语气轻松随意（初次见面）
- 只返回JSON：{{"questions": ["问题1", "问题2", "问题3", "问题4"]}}""",

    "vi": """\
Người dùng A đang bắt đầu cuộc trò chuyện lần đầu với người dùng B.
Hãy viết 4 câu hỏi mở đầu tự nhiên bằng tiếng Việt mà người dùng A nói trực tiếp với B.

[Người dùng A]
{my_info}

[Người dùng B]
{other_info}

Yêu cầu:
- Chỉ viết câu hỏi, tuyệt đối không thêm lời giải thích hay tự ti (vd: "Tôi không biết nhiều, nhưng...")
- Không dùng góc nhìn bên ngoài như "cả hai bạn", "các bạn"
- Không thêm kính ngữ sau tên
- Ngôi thứ nhất ("Tôi cũng", "Tôi") chỉ dùng khi tự nhiên, không ép vào mỗi câu
- Dựa trên sở thích của B hoặc điểm chung
- {priority}
- Ngắn gọn, tự nhiên (lần đầu gặp)
- Chỉ trả về JSON: {{"questions": ["câu1", "câu2", "câu3", "câu4"]}}""",

    "ja": """\
ユーザーAがユーザーBに初めて話しかける場面です。
ユーザーAがBに直接話しかける自然な会話の入り口となる質問を4つ日本語で作ってください。

[ユーザーA]
{my_info}

[ユーザーB]
{other_info}

条件：
- 質問だけを書くこと。余計な説明・謙遜表現は絶対に禁止（例：「よく知らないけど」など）
- 「お二人とも」「二人が」などの第三者視点の表現は使わない
- 名前の後に敬称（「さん」など）をつけない
- 一人称（「私も」「僕も」）は自然な場合のみ使用 — 全文に無理やり入れない
- Bの興味や共通点を話題にする
- {priority}
- 短く気軽な話しかけ方（初対面）
- JSONのみ返す: {{"questions": ["質問1", "質問2", "質問3", "質問4"]}}""",
}


# 가중치 → 주제 레이블 (언어별)
_WEIGHT_LABELS = {
    "ko": {
        "interests":   "공통 관심사",
        "purpose":     "교류 목적(언어교환·학업·문화교류 등)",
        "language":    "언어 및 언어 학습",
        "personality": "성향·라이프스타일",
        "major":       "전공·학문",
        "nationality": "문화·국적 차이",
    },
    "en": {
        "interests":   "shared interests",
        "purpose":     "exchange goals (language, study, culture, etc.)",
        "language":    "language & language learning",
        "personality": "personality & lifestyle",
        "major":       "major & academics",
        "nationality": "culture & nationality",
    },
    "zh": {
        "interests":   "共同兴趣",
        "purpose":     "交流目的（语言、学习、文化等）",
        "language":    "语言与语言学习",
        "personality": "性格与生活方式",
        "major":       "专业与学业",
        "nationality": "文化与国籍",
    },
    "vi": {
        "interests":   "sở thích chung",
        "purpose":     "mục đích giao lưu (ngôn ngữ, học tập, văn hóa…)",
        "language":    "ngôn ngữ và học ngôn ngữ",
        "personality": "tính cách và lối sống",
        "major":       "chuyên ngành và học thuật",
        "nationality": "văn hóa và quốc tịch",
    },
    "ja": {
        "interests":   "共通の趣味",
        "purpose":     "交流目的（語学・学業・文化など）",
        "language":    "言語と語学学習",
        "personality": "性格・ライフスタイル",
        "major":       "専攻・学問",
        "nationality": "文化・国籍の違い",
    },
}

_PRIORITY_INTRO = {
    "ko": "특히 다음 주제를 우선적으로 질문에 녹여낼 것 (중요도 순):",
    "en": "Prioritize these topics in the questions (by importance):",
    "zh": "重点将以下话题融入问题中（按重要性排序）：",
    "vi": "Ưu tiên đưa các chủ đề sau vào câu hỏi (theo mức độ quan trọng):",
    "ja": "特に以下のトピックを質問に優先的に盛り込むこと（重要度順）：",
}


def _priority_hint(req: IcebreakingRequest) -> str:
    """가중치 상위 2개 주제를 반환한다."""
    locale = req.locale if req.locale in _WEIGHT_LABELS else "ko"
    labels = _WEIGHT_LABELS[locale]
    intro  = _PRIORITY_INTRO[locale]

    scores = {
        "interests":   req.weight_interests,
        "purpose":     req.weight_purpose,
        "language":    req.weight_language,
        "personality": req.weight_personality,
        "major":       req.weight_major,
        "nationality": req.weight_nationality,
    }
    top2 = sorted(scores, key=scores.get, reverse=True)[:2]
    items = "\n".join(f"  - {labels[k]}" for k in top2)
    return f"{intro}\n{items}"


def _build_prompt(req: IcebreakingRequest, lang_name: str) -> str:
    locale = req.locale if req.locale in _PROMPT_TEMPLATE else "ko"
    template = _PROMPT_TEMPLATE[locale]

    none_ko  = {"ko": "없음", "en": "none", "zh": "无", "vi": "không có", "ja": "なし"}
    none_str = none_ko.get(locale, "없음")

    my_info = (
        f"name: {req.my_name}, country: {req.my_country}, major: {req.my_major}, "
        f"interests: {', '.join(req.my_interests) or none_str}, "
        f"purposes: {', '.join(req.my_purposes) or none_str}, "
        f"personality: {', '.join(req.my_personalities) or none_str}"
    )
    other_info = (
        f"name: {req.other_name}, country: {req.other_country}, major: {req.other_major}, "
        f"interests: {', '.join(req.other_interests) or none_str}"
    )
    priority = _priority_hint(req)
    return template.format(my_info=my_info, other_info=other_info, priority=priority)


async def _call_gemini(prompt: str, api_key: str) -> list[str]:
    from google import genai
    from google.genai import types
    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
        ),
    )
    data = json.loads(response.text)
    return data.get("questions", [])


@router.post("/chat/icebreaking")
async def get_icebreaking_questions(req: IcebreakingRequest):
    """두 유저 프로필을 바탕으로 AI 아이스브레이킹 질문 4개를 생성한다.
    Gemini → fallback 순으로 시도한다."""

    locale = req.locale if req.locale in _LOCALE_NAMES else "ko"
    lang_name = _LOCALE_NAMES[locale]
    fallback = _FALLBACK.get(locale, _FALLBACK["ko"])

    gemini_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not gemini_key:
        return {"questions": fallback}

    prompt = _build_prompt(req, lang_name)

    try:
        questions = await _call_gemini(prompt, gemini_key)
        if questions:
            return {"questions": questions}
    except Exception as e:
        print(f"[icebreaking] Gemini 실패: {e}")

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
