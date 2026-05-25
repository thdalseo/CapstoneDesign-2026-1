import os

from fastapi import APIRouter, HTTPException
from google import genai
from pydantic import BaseModel


router = APIRouter(prefix="/api", tags=["translation"])

_LANGUAGE_NAMES = {
    "ko": "Korean",
    "en": "English",
    "ja": "Japanese",
    "zh": "Chinese",
    "vi": "Vietnamese",
}


class TranslateRequest(BaseModel):
    text: str
    target_lang: str = "ko"


class TranslateResponse(BaseModel):
    translated_text: str


@router.post("/translate", response_model=TranslateResponse)
def translate_text(req: TranslateRequest):
    text = req.text.strip()
    if not text:
        return TranslateResponse(translated_text=req.text)

    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(
            status_code=500,
            detail="GEMINI_API_KEY is not configured.",
        )

    target_lang = req.target_lang.lower().strip()
    target_name = _LANGUAGE_NAMES.get(target_lang, target_lang)

    prompt = (
        "Translate the following text for a university student exchange app.\n"
        f"Target language: {target_name} ({target_lang}).\n"
        "Return only the translated text. Do not add explanations, labels, "
        "quotes, markdown, or extra commentary.\n\n"
        f"Text:\n{text}"
    )

    try:
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Translation API request failed: {exc}",
        ) from exc

    translated = (getattr(response, "text", None) or "").strip()
    if not translated:
        raise HTTPException(
            status_code=502,
            detail="Translation API returned an empty response.",
        )

    return TranslateResponse(translated_text=translated)
