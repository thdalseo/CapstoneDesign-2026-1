from app.core.database import engine

try:
    # 파이썬이 DB 창고 문을 두드려보는 코드입니다
    connection = engine.connect()
    print("🎉 파이썬과 MySQL 연결 완벽 성공! 🎉")
    connection.close()
except Exception as e:
    print("🚨 연결 실패! 에러 내용:", e)