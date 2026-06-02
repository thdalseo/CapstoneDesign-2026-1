# Bridge

외국인 유학생과 한국 학생 간의 교류를 돕는 모바일 플랫폼

## 개요

한국 대학 내 외국인 유학생 수는 꾸준히 증가하고 있으나, 유학생과 내국인 학생 간의 실질적인 교류는 여전히 부족한 실정이다. 기존 버디 프로그램·튜터링 등 오프라인 기반 교류는 복잡한 선발 절차, 제한적인 참여 조건, 수동 매칭의 한계로 인해 일회성 만남에 그치는 경우가 많다.

Bridge는 관심사·학과·성향을 반영한 가중치 기반 매칭 알고리즘과 실시간 AI 번역을 통해, 외국어 능력과 무관하게 누구나 교류할 수 있는 환경을 제공한다.

## 기술 스택

| 분류 | 기술 |
|------|------|
| Frontend | Flutter (Dart) |
| Backend | FastAPI (Python) |
| Database | SQLite |
| 실시간 통신 | WebSocket |
| 다국어 | easy_localization (ko, en, ja, zh, vi) |

## 주요 기능

- **스마트 매칭** — 관심사·학과·국적·성향 항목별 가중치 알고리즘으로 개인화 추천
- **실시간 채팅** — WebSocket 기반 채팅, AI 아이스브레이킹 제안, 메시지 번역
- **언어교환 세션** — 채팅방 내 언어교환 요청 및 타이머 기반 세션 진행·기록
- **도움 게시판** — 행정·학업·생활 등 카테고리별 도움 요청 및 수락
- **다국어 지원** — 한국어·영어·일본어·중국어·베트남어 UI 전환

## 실행 방법

**백엔드**
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**프론트엔드**
```bash
flutter pub get
flutter run
```

## 프로젝트 구조

```
CapstoneDesign-2026-1/
├── lib/
│   ├── models/          # 데이터 모델
│   ├── screens/         # 화면
│   ├── widgets/         # 공통 위젯
│   ├── services/        # API·WebSocket 서비스
│   ├── theme/           # 앱 테마
│   └── constants/       # 상수
├── backend/
│   ├── app/
│   │   ├── models/      # DB 모델
│   │   ├── routers/     # API 라우터
│   │   └── core/        # DB·필터 설정
│   └── main.py
└── assets/
    └── translations/    # 다국어 번역 파일
```

## 팀원

| 이름 | 역할 |
|------|------|
| 김석환 | BE |
| 김재민 | DB |
| 송민서 | FE, AI |
