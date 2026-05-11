from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
# 이전에 만든 파일에서 함수를 가져옵니다.
from app.email_verifier import send_verification_email

app = FastAPI()

verification_db = {}

# 요청 바디 정의 (JSON 형태로 데이터를 받기 위함)
class EmailRequest(BaseModel):
    email: str  # 이메일 형식 검증을 위해 EmailStr을 써도 좋지만, 
                # 일단 str로 받고 로직에서 @kangwon.ac.kr를 체크합시다.

class VerifyRequest(BaseModel):
    email: str
    code: str

@app.post("/auth/send-code")
async def request_code(request: EmailRequest):
    # 1. 메일 발송 함수 호출
    code, message = send_verification_email(request.email)
    
    # 2. 결과 처리
    if code is None:
        # 강원대 메일이 아니거나 SMTP 오류 발생 시 400 에러 반환
        raise HTTPException(status_code=400, detail=message)
    
    # 3. 코드 저장 (중요!)
    # 여기서 생성된 code를 DB나 임시 저장소(Redis 등)에 저장해야 
    # 나중에 사용자가 입력한 번호와 대조할 수 있습니다.
    # 우선은 로그로 확인해 보세요.
    verification_db[request.email] = code
    print(f"👀 [서버 로그] 현재 임시 저장소 상태: {verification_db}")
    print(f"이메일: {request.email} / 생성된 코드: {code}")
    
    return {"message": "인증 코드가 발송되었습니다."}

@app.post("/auth/verify-code")
async def verify_code(request: VerifyRequest):
    # 1. 임시 DB에서 해당 이메일로 발급된 코드를 찾습니다.
    saved_code = verification_db.get(request.email)
    
    # 2. 코드가 아예 없으면 (발송한 적이 없거나 서버가 꺼졌었음)
    if saved_code is None:
        raise HTTPException(status_code=404, detail="인증 번호 발송을 먼저 해주세요.")
    
    # 3. 코드가 일치하는지 확인
    if saved_code == request.code:
        # 인증이 완료되었으므로 임시 DB에서 지워줍니다 (재사용 방지)
        del verification_db[request.email]
        return {"message": "학교 메일 인증이 완료되었습니다!"}
    else:
        raise HTTPException(status_code=400, detail="인증 코드가 일치하지 않습니다.")
