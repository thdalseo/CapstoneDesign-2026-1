import json
import os
from typing import Dict, List

import asyncio

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from sqlalchemy import or_
from sqlalchemy.orm import Session

from datetime import datetime

from app.core.database import get_db
from app.core.profanity_filter import contains_profanity
from app.models.user import ChatMessage, ChatRoom, ChatRoomRead, User
from app.notification_utils import create_notification, notification_dict

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
    # 매칭 가중치 (합계 = 100)
    weight_purpose: int = 25
    weight_interests: int = 20
    weight_language: int = 18
    weight_personality: int = 17
    weight_major: int = 8
    weight_year: int = 7
    weight_nationality: int = 5
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
        last_msg = (
            db.query(ChatMessage)
            .filter(ChatMessage.room_id == room.id)
            .order_by(ChatMessage.created_at.desc())
            .first()
        )
        # 읽음 기준 시각
        read_record = (
            db.query(ChatRoomRead)
            .filter(ChatRoomRead.room_id == room.id, ChatRoomRead.user_id == user_id)
            .first()
        )
        last_read_at = read_record.last_read_at if read_record else datetime.min

        unread_count = (
            db.query(ChatMessage)
            .filter(
                ChatMessage.room_id == room.id,
                ChatMessage.sender_id != user_id,
                ChatMessage.created_at > last_read_at,
                ChatMessage.is_system == False,
            )
            .count()
        )

        result.append({
            "room_id": room.id,
            "other_user_id": str(other_id),
            "other_user_name": other.name if other else f"User {other_id}",
            "other_user_country": (other.country or "") if other else "",
            "other_user_major": (other.major or "") if other else "",
            "other_user_year": (other.year or "") if other else "",
            "other_user_interests": [i.interest for i in other.interests] if other else [],
            "other_user_languages": [l.language for l in other.languages] if other else [],
            "other_user_description": (other.description or "") if other else "",
            "last_message": last_msg.content if last_msg else None,
            "last_message_time": last_msg.created_at.isoformat() if last_msg else None,
            "unread_count": unread_count,
        })
    return result


class ReadRoomRequest(BaseModel):
    user_id: int


@router.post("/chat/rooms/{room_id}/read")
def mark_room_read(
    room_id: int,
    req: ReadRoomRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """채팅방을 읽음 처리하고 WebSocket으로 상대방에게 알린다.
    동기 핸들러(def)로 선언해 asyncio 이벤트 루프 블로킹을 방지한다.
    WebSocket 브로드캐스트는 BackgroundTask로 이벤트 루프에 위임한다."""
    now = datetime.utcnow()
    record = (
        db.query(ChatRoomRead)
        .filter(ChatRoomRead.room_id == room_id, ChatRoomRead.user_id == req.user_id)
        .first()
    )
    if record:
        record.last_read_at = now
    else:
        db.add(ChatRoomRead(room_id=room_id, user_id=req.user_id, last_read_at=now))
    db.commit()

    # 브로드캐스트를 BackgroundTask로 등록 → 응답 후 이벤트 루프에서 실행
    payload = {
        "type": "read",
        "user_id": req.user_id,
        "read_at": now.isoformat(),
    }
    background_tasks.add_task(_broadcast_background, room_id, payload)

    return {"ok": True}


async def _broadcast_background(room_id: int, payload: dict):
    """BackgroundTask 전용: 이벤트 루프 안에서 안전하게 브로드캐스트."""
    await manager.broadcast(room_id, payload, exclude=None)


@router.get("/chat/rooms/{room_id}/read-status")
def get_read_status(room_id: int, user_id: int, db: Session = Depends(get_db)):
    """상대방의 마지막 읽음 시각을 반환한다."""
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="채팅방을 찾을 수 없습니다.")
    other_id = room.user_id_b if room.user_id_a == user_id else room.user_id_a
    other_read = (
        db.query(ChatRoomRead)
        .filter(ChatRoomRead.room_id == room_id, ChatRoomRead.user_id == other_id)
        .first()
    )
    return {
        "other_last_read_at": other_read.last_read_at.isoformat() if other_read else None
    }


@router.delete("/chat/rooms/{room_id}")
def leave_room(room_id: int, user_id: int, db: Session = Depends(get_db)):
    """채팅방을 나간다. 참여자만 삭제 가능하며 메시지도 함께 삭제된다."""
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="채팅방을 찾을 수 없습니다.")
    if room.user_id_a != user_id and room.user_id_b != user_id:
        raise HTTPException(status_code=403, detail="권한이 없습니다.")
    db.delete(room)
    db.commit()
    return {"ok": True}


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


# ── AI 문장 교정 ──────────────────────────────────────────────────────────────

class CorrectionRequest(BaseModel):
    text: str
    locale: str = "ko"


_CORRECTION_PROMPT = {
    "ko": """\
아래 문장을 엄격하게 검토하세요. 이 문장을 작성한 사람은 한국어를 배우는 외국인일 수 있습니다.

문장: "{text}"

반드시 오류로 판단해야 하는 경우 (is_correct=false):
1. 어순이 어색한 경우 (예: "갔었어요 어제" → "어제 갔어요")
2. 조사 오류 (예: "음악을 관심 있어요" → "음악에 관심 있어요")
3. 시제 오류 (예: 과거/현재/미래 혼용)
4. 어휘 선택이 어색한 경우
5. 문법적으로 틀린 경우

판단 기준:
- 한국어 원어민이 자연스럽게 쓰는 문장인지 엄격하게 판단
- 조금이라도 어색하면 is_correct=false로 처리
- 완벽히 자연스러울 때만 is_correct=true

출력:
- is_correct=false면: corrected에 교정된 문장, explanation에 오류 이유 한 줄 (한국어, 50자 이내)
- is_correct=true면: corrected는 원문 그대로, explanation은 빈 문자열
- JSON만 반환: {{"is_correct": true/false, "corrected": "...", "explanation": "..."}}""",

    "en": """\
Please review the following sentence strictly. The writer may be a non-native English speaker.

Sentence: "{text}"

Mark as incorrect (is_correct=false) if:
1. Word order is unnatural
2. Wrong preposition or article
3. Tense error
4. Awkward word choice
5. Grammatically wrong

Rules:
- Judge as a native English speaker would — be strict
- Even slightly unnatural = is_correct=false
- Only mark true if perfectly natural
- corrected: fixed sentence if false, original if true
- explanation: one line in English (under 50 chars) if false, empty string if true
- Return JSON only: {{"is_correct": true/false, "corrected": "...", "explanation": "..."}}""",

    "zh": """\
请严格检查以下句子。写这句话的人可能是正在学中文的外国人。

句子："{text}"

以下情况必须判断为错误（is_correct=false）：
1. 语序不自然
2. 助词/介词用错
3. 时态错误
4. 词汇选择不当
5. 语法错误

判断标准：
- 以母语者标准严格判断
- 稍有不自然即为is_correct=false
- 完全自然才可以is_correct=true
- corrected：错误时填修正后句子，正确时填原文
- explanation：错误时用中文一句话说明原因（50字以内），正确时为空字符串
- 只返回JSON：{{"is_correct": true/false, "corrected": "...", "explanation": "..."}}""",

    "vi": """\
Hãy kiểm tra câu sau một cách nghiêm ngặt. Người viết có thể đang học tiếng Việt.

Câu: "{text}"

Phải đánh dấu là sai (is_correct=false) nếu:
1. Trật tự từ không tự nhiên
2. Giới từ hoặc trợ từ sai
3. Lỗi thì
4. Chọn từ không phù hợp
5. Sai ngữ pháp

Tiêu chí:
- Đánh giá theo tiêu chuẩn người bản ngữ — nghiêm khắc
- Hơi không tự nhiên = is_correct=false
- Chỉ true khi hoàn toàn tự nhiên
- corrected: câu đã sửa nếu sai, nguyên bản nếu đúng
- explanation: một câu tiếng Việt giải thích lỗi (dưới 50 ký tự) nếu sai, chuỗi rỗng nếu đúng
- Chỉ trả về JSON: {{"is_correct": true/false, "corrected": "...", "explanation": "..."}}""",

    "ja": """\
以下の文を厳しく確認してください。書いた人は日本語を学んでいる外国人かもしれません。

文: "{text}"

誤りと判断すべき場合（is_correct=false）：
1. 語順が不自然
2. 助詞の誤り
3. 時制の誤り
4. 語彙の選択が不自然
5. 文法的に誤っている

判断基準：
- ネイティブの基準で厳しく判断
- 少しでも不自然ならis_correct=false
- 完全に自然な場合のみis_correct=true
- corrected：誤りなら修正後の文、正しければ原文のまま
- explanation：誤りなら日本語で一言説明（50文字以内）、正しければ空文字
- JSONのみ返す: {{"is_correct": true/false, "corrected": "...", "explanation": "..."}}""",
}


async def _call_gemini_correction(prompt: str, api_key: str) -> dict:
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
    return json.loads(response.text)


@router.post("/chat/correct")
async def correct_sentence(req: CorrectionRequest):
    """입력 문장을 AI가 교정한다. Gemini 실패 시 원문 그대로 반환."""
    locale = req.locale if req.locale in _CORRECTION_PROMPT else "ko"
    template = _CORRECTION_PROMPT[locale]
    prompt = template.format(text=req.text.replace('"', "'"))

    gemini_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not gemini_key:
        return {"is_correct": True, "corrected": req.text, "explanation": ""}

    try:
        result = await _call_gemini_correction(prompt, gemini_key)
        return {
            "is_correct": bool(result.get("is_correct", True)),
            "corrected": result.get("corrected", req.text),
            "explanation": result.get("explanation", ""),
        }
    except Exception as e:
        print(f"[correct] Gemini 실패: {e}")
        return {"is_correct": True, "corrected": req.text, "explanation": ""}


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
            if not content:
                continue

            # sender_id 유효성 검사 — 비어 있거나 정수로 변환 불가능하면 무시
            raw_sender = data.get("sender_id")
            try:
                sender_id_int = int(raw_sender)
                if sender_id_int <= 0:
                    raise ValueError
            except (TypeError, ValueError):
                await ws.send_json({
                    "type": "error",
                    "code": "invalid_sender",
                    "message": "유효하지 않은 사용자입니다. 다시 로그인해주세요.",
                })
                continue

            # 금칙어 검사 — __로 시작하는 시스템/세션 메시지는 제외
            if not content.startswith('__') and contains_profanity(content):
                await ws.send_json({
                    "type": "error",
                    "code": "profanity",
                    "message": "부적절한 표현이 포함되어 있어요.",
                })
                continue

            # DB 저장
            msg = ChatMessage(
                room_id=room_id,
                sender_id=sender_id_int,
                content=content,
                is_system=False,
            )
            db.add(msg)
            db.commit()
            db.refresh(msg)

            notification_payload = None
            try:
                room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
                sender = (
                    db.query(User)
                    .filter(User.id == sender_id_int)
                    .first()
                )
                if room and sender:
                    receiver_id = (
                        room.user_id_b
                        if room.user_id_a == sender.id
                        else room.user_id_a
                    )
                    notification = create_notification(
                        db,
                        user_id=receiver_id,
                        type="chat",
                        title="새 채팅 메시지",
                        body=f"{sender.name}: {content}",
                        source_type="chat_room",
                        source_id=str(room_id),
                        dedupe_key=f"chat:{msg.id}:{receiver_id}",
                    )
                    db.commit()
                    db.refresh(notification)
                    notification_payload = notification_dict(notification)
            except Exception as e:
                db.rollback()
                print(f"[notification] 채팅 알림 생성 실패: {e}")

            # 보낸 사람을 제외한 나머지에게 브로드캐스트
            # (보낸 사람은 낙관적 업데이트로 이미 UI에 표시됨)
            payload = {
                "type": "message",
                "id": msg.id,
                "sender_id": msg.sender_id,
                "content": msg.content,
                "timestamp": msg.created_at.isoformat(),
                "is_system": False,
            }
            if notification_payload:
                payload["notification"] = notification_payload

            await manager.broadcast(room_id, payload, exclude=ws)

    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(room_id, ws)
