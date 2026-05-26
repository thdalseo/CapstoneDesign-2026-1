from sqlalchemy.orm import Session
from typing import List, Dict
from datetime import datetime

# 팀원의 실제 DB 모델 파일(app/models/user.py)에서 필요한 모델들을 임포트합니다.
from app.models.user import (
    User, UserInterest, UserExchangePurpose, UserPersonality, UserLanguage, Match
)

# ==========================================
# 1. 기획안 표준 가중치 상숫값 정의
# ==========================================
# 유저별 커스텀 가중치 테이블이 없으므로 이미지의 기본 가중치(합산 100)를 사용합니다.
DEFAULT_WEIGHTS = {
    "purpose": 25,
    "interest": 20,
    "language": 18,
    "personality": 17, # 기존 'trait'가 실제 모델에서는 'personality'로 명명됨
    "dept": 12,        # 학과/전공
    "nationality": 8   # 국적(내국인/외국인 조합)
}

# ==========================================
# 2. 매칭 점수 산출 코어 로직
# ==========================================

def calculate_matching_score(me: User, peer: User) -> float:
    """
    팀원의 user.py DB 모델 객체를 직접 받아 기획안 수식대로 매칭 점수를 계산합니다.
    """
    
    def get_intersection_score(my_relations, peer_relations, attr_name: str) -> float:
        """다중 선택 관계형 테이블에서 문자열 값을 추출해 교집합 비율(%)을 계산"""
        # SQLAlchemy 관계형 객체에서 실제 텍스트 값만 뽑아 리스트로 변환
        my_list = [getattr(item, attr_name) for item in my_relations]
        peer_list = [getattr(item, attr_name) for item in peer_relations]
        
        if not my_list:
            return 0.0
        
        intersection = set(my_list).intersection(set(peer_list))
        return (len(intersection) / len(my_list)) * 100

    # 1) 다중 선택 항목 유사도 산출 (user.py 내부의 back_populates 관계 활용)
    score_interest = get_intersection_score(me.interests, peer.interests, "interest")
    score_purpose = get_intersection_score(me.exchange_purposes, peer.exchange_purposes, "purpose")
    score_language = get_intersection_score(me.languages, peer.languages, "language")
    score_personality = get_intersection_score(me.personalities, peer.personalities, "personality")

    # 2) 단일 선택 항목 점수 산출
    # 학과(Major) 및 단과대(College) 점수 (동일과 100, 동일단과대 50, 타과 0)
    if me.major == peer.major:
        score_dept = 100.0
    elif me.college == peer.college:
        score_dept = 50.0
    else:
        score_dept = 0.0

    # 국적 점수 (내국인 + 외국인 조합이면 100, 같으면 0)
    # user.py의 is_international 필드 활용 (True: 외국인, False: 내국인)
    score_nationality = 100.0 if me.is_international != peer.is_international else 0.0

    # 3) 기본 가중치 적용 및 최종 합산
    total_score = (
        (score_interest * (DEFAULT_WEIGHTS["interest"] / 100)) +
        (score_purpose * (DEFAULT_WEIGHTS["purpose"] / 100)) +
        (score_language * (DEFAULT_WEIGHTS["language"] / 100)) +
        (score_personality * (DEFAULT_WEIGHTS["personality"] / 100)) +
        (score_dept * (DEFAULT_WEIGHTS["dept"] / 100)) +
        (score_nationality * (DEFAULT_WEIGHTS["nationality"] / 100))
    )

    return round(total_score, 1)


# ==========================================
# 3. DB 조회 및 최적의 매칭 추천/저장 함수
# ==========================================

def get_and_save_top_matches(db: Session, target_user_id: int, top_n: int = 5) -> List[dict]:
    """
    실제 DB에서 유저 정보를 읽어와 점수를 매긴 후, 
    정렬된 결과를 반환함과 동시에 'matches' 테이블에 이력을 저장/갱신합니다.
    """
    # 1) 기준 유저(나) 정보 조회
    me = db.query(User).filter(User.id == target_user_id).first()
    if not me:
        raise ValueError(f"ID가 {target_user_id}인 유저를 찾을 수 없습니다.")

    # 2) 매칭 대상 후보군 조회 (본인 제외, 인증된 유저만)
    peers = db.query(User).filter(User.id != target_user_id, User.is_verified == True).all()

    raw_matches = []
    for peer in peers:
        score = calculate_matching_score(me, peer)
        raw_matches.append({
            "peer": peer,
            "score": score
        })

    # 3) 점수 높은 순(내림차순) 정렬
    raw_matches.sort(key=lambda x: x["score"], reverse=True)
    top_matches = raw_matches[:top_n]

    results = []
    for match_data in top_matches:
        peer = match_data["peer"]
        score = match_data["score"]

        # 4) 실제 user.py의 'matches' 테이블에 연산 결과 기록/갱신 (Upsert 로직)
        # 짝 구조 유연성을 위해 user_id_a에 작은 ID, user_id_b에 큰 ID가 들어가도록 정렬 배치
        id_a, id_b = min(me.id, peer.id), max(me.id, peer.id)
        
        existing_match = db.query(Match).filter(
            Match.user_id_a == id_a, 
            Match.user_id_b == id_b
        ).first()

        if existing_match:
            # 이미 기존 매칭 데이터가 있다면 점수 최신화
            existing_match.match_score = int(score)
            existing_match.created_at = datetime.utcnow()
        else:
            # 없다면 새로 생성하여 저장
            new_match = Match(
                user_id_a=id_a,
                user_id_b=id_b,
                match_score=int(score),
                is_active=True
            )
            db.add(new_match)

        results.append({
            "peer_id": peer.id,
            "peer_name": peer.name,
            "country": peer.country,
            "matching_score": score
        })

    db.commit() # 변경사항 DB에 최종 반영
    return results