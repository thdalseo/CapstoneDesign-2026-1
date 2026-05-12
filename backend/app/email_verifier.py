import smtplib
import random
import string
import os
from email.message import EmailMessage
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 465

def generate_verification_code(length=6):
    """6자리 숫자 인증 코드를 생성합니다."""
    return ''.join(random.choices(string.digits, k=length))

def is_knu_mail(email: str):
    """강원대학교 메일인지 확인합니다."""
    return email.endswith("@kangwon.ac.kr")

def send_verification_email(target_email: str):
    """실제 인증 메일을 발송하고 생성된 코드를 반환합니다."""
    if not is_knu_mail(target_email):
        return None, "강원대학교 메일 주소가 아닙니다."

    code = generate_verification_code()
    
    msg = EmailMessage()
    msg['Subject'] = "[KNU BRIDGE] 이메일 인증 번호"
    msg['From'] = SMTP_USER
    msg['To'] = target_email
    msg.set_content(f"안녕하세요! 서비스 이용을 위한 인증 번호는 [{code}] 입니다.\n10분 내에 입력해 주세요.")

    try:
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as smtp:
            smtp.login(SMTP_USER, SMTP_PASSWORD)
            smtp.send_message(msg)
        return code, "발송 성공"
    except Exception as e:
        return None, str(e)