from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Bridge API 서버 정상 작동 중"}