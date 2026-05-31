"""
금칙어 필터 모듈
- 서버 시작 시 로컬 파일(폴백) 로드 → GitHub 최신본 fetch
- 24시간마다 자동 갱신
- contains_profanity(text) 로 검사
"""

import asyncio
import csv
import io
import logging
import os
from pathlib import Path
from typing import Set

import httpx

logger = logging.getLogger(__name__)

# GitHub Raw URL
_GITHUB_BASE = "https://raw.githubusercontent.com/Tanat05/korean-profanity-resources/main"
_SLANG_CSV_URL = f"{_GITHUB_BASE}/slang.csv"
_LOL_TXT_URL = f"{_GITHUB_BASE}/리그오브레전드_필터링리스트_2020.txt"

# 로컬 폴백 경로
_DATA_DIR = Path(__file__).parent / "data"
_LOCAL_CSV = _DATA_DIR / "slang.csv"
_LOCAL_TXT = _DATA_DIR / "lol_filter.txt"

# 금칙어 Set (소문자)
_bad_words: Set[str] = set()

# 갱신 주기 (초)
_REFRESH_INTERVAL = 24 * 3600


# ── 파싱 ─────────────────────────────────────────────────────────────────────

def _parse_csv(text: str) -> Set[str]:
    """slang.csv 파싱: 첫 행(헤더) 건너뜀, 각 행 첫 컬럼 추출"""
    words: Set[str] = set()
    reader = csv.reader(io.StringIO(text))
    next(reader, None)  # 헤더 건너뜀
    for row in reader:
        if row:
            word = row[0].strip().lower()
            if word:
                words.add(word)
    return words


def _parse_txt(text: str) -> Set[str]:
    """lol_filter.txt 파싱: 줄당 한 단어"""
    words: Set[str] = set()
    for line in text.splitlines():
        word = line.strip().lower()
        if word:
            words.add(word)
    return words


# ── 로컬 파일 로드 ────────────────────────────────────────────────────────────

def _load_local() -> Set[str]:
    words: Set[str] = set()
    try:
        words |= _parse_csv(_LOCAL_CSV.read_text(encoding="utf-8"))
        logger.info(f"[profanity] 로컬 CSV 로드: {len(words)}개")
    except Exception as e:
        logger.warning(f"[profanity] 로컬 CSV 로드 실패: {e}")
    try:
        txt_words = _parse_txt(_LOCAL_TXT.read_text(encoding="utf-8"))
        words |= txt_words
        logger.info(f"[profanity] 로컬 TXT 로드 후 총 {len(words)}개")
    except Exception as e:
        logger.warning(f"[profanity] 로컬 TXT 로드 실패: {e}")
    return words


# ── GitHub fetch ──────────────────────────────────────────────────────────────

async def _fetch_from_github() -> Set[str]:
    words: Set[str] = set()
    async with httpx.AsyncClient(timeout=30) as client:
        # slang.csv
        try:
            resp = await client.get(_SLANG_CSV_URL)
            if resp.status_code == 200:
                words |= _parse_csv(resp.text)
                logger.info(f"[profanity] GitHub CSV fetch 완료: {len(words)}개")
        except Exception as e:
            logger.warning(f"[profanity] GitHub CSV fetch 실패: {e}")

        # lol_filter.txt
        try:
            resp = await client.get(_LOL_TXT_URL)
            if resp.status_code == 200:
                words |= _parse_txt(resp.text)
                logger.info(f"[profanity] GitHub TXT fetch 후 총 {len(words)}개")
        except Exception as e:
            logger.warning(f"[profanity] GitHub TXT fetch 실패: {e}")

    return words


# ── 갱신 ─────────────────────────────────────────────────────────────────────

async def refresh():
    """GitHub에서 최신 금칙어 목록을 fetch해 갱신. 실패 시 기존 유지."""
    global _bad_words
    fetched = await _fetch_from_github()
    if fetched:
        _bad_words = fetched
        logger.info(f"[profanity] 갱신 완료 — 총 {len(_bad_words)}개")
    else:
        logger.warning("[profanity] GitHub fetch 결과 없음 — 기존 목록 유지")


async def start_auto_refresh(interval_seconds: int = _REFRESH_INTERVAL):
    """서버 시작 시 로컬 파일 로드 → GitHub fetch → 주기적 갱신"""
    global _bad_words

    # 1단계: 로컬 폴백 (즉시)
    _bad_words = _load_local()

    # 2단계: GitHub 최신본 (비동기)
    await refresh()

    # 3단계: 주기적 갱신
    while True:
        await asyncio.sleep(interval_seconds)
        await refresh()


# ── 공개 API ─────────────────────────────────────────────────────────────────

def contains_profanity(text: str) -> bool:
    """텍스트에 금칙어가 포함되어 있으면 True"""
    if not text:
        return False
    text_lower = text.lower()
    return any(word in text_lower for word in _bad_words)


def word_count() -> int:
    """현재 로드된 금칙어 수"""
    return len(_bad_words)
