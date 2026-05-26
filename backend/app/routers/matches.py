from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

# DB 세션을 가져오기 위한 의존성 주입 함수와 매칭 알고리즘 함수를 임포트합니다.
from app.core.database import get_db
from matching_db_service import get_and_save_top_matches

router = APIRouter(prefix="/api/v1/matches", tags=["Matches"])

@router.get("/recommend/{user_id}")
def get_recommended_partners(user_id: int, db: Session = Depends(get_db)):
    """
    Flutter 앱에서 특정 유저 ID의 '추천 매칭 리스트'를 요청할 때 호출되는 메인 함수입니다.
    """
    try:
        # 알고리즘을 돌려 최적의 타겟 5명을 뽑고, DB(matches 테이블)에 기록 후 결과를 가져옵니다.
        recommendations = get_and_save_top_matches(db=db, target_user_id=user_id, top_n=5)
        
        return {
            "status": "success",
            "data": recommendations
        }
        
    except ValueError as val_err:
        # 유저를 찾지 못했을 때의 예외 처리 (404 예외)
        raise HTTPException(status_code=404, detail=str(val_err))
    except Exception as e:
        # 기타 서버 에러 처리 (500 예외)
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")