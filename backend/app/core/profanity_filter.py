"""
금칙어 필터 모듈 (Aho-Corasick 기반)
- 서버 시작 시 로컬 파일(폴백) 로드 → GitHub 최신본 fetch
- 24시간마다 자동 갱신
- 단어 목록 변경 시 자동마톤 재빌드
- contains_profanity(text) → O(n) 단일 패스 검사
"""

import asyncio
import csv
import io
import logging
import os
from collections import deque
from pathlib import Path
from typing import Dict, List, Optional, Set

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

# 갱신 주기 (초)
_REFRESH_INTERVAL = 24 * 3600


# ── Aho-Corasick 자동마톤 ─────────────────────────────────────────────────────

class _AhoCorasick:
    """
    Aho-Corasick 다중 패턴 문자열 매칭 자동마톤.

    복잡도
    -------
    - 빌드: O(Σ|패턴|)
    - 검색: O(|텍스트| + 매치 수)   ← 패턴 수에 무관
    """

    def __init__(self) -> None:
        # 상태 전이 테이블: goto[state][char] = next_state
        self.goto: List[Dict[str, int]] = [{}]
        # 실패 링크: 현재 상태에서 매칭 실패 시 돌아갈 상태
        self.fail: List[int] = [0]
        # 출력: 해당 상태에서 매칭 완료된 패턴들
        self.output: List[Set[str]] = [set()]

    def add_word(self, word: str) -> None:
        state = 0
        for ch in word:
            if ch not in self.goto[state]:
                self.goto[state][ch] = len(self.goto)
                self.goto.append({})
                self.fail.append(0)
                self.output.append(set())
            state = self.goto[state][ch]
        self.output[state].add(word)

    def build(self) -> None:
        """BFS로 실패 링크와 출력 링크를 계산한다 (KMP의 일반화)."""
        q: deque[int] = deque()

        # 루트(0)의 직접 자식은 실패 → 루트
        for ch, s in self.goto[0].items():
            self.fail[s] = 0
            q.append(s)

        while q:
            r = q.popleft()
            for ch, s in self.goto[r].items():
                q.append(s)

                # 실패 링크 계산
                f = self.fail[r]
                while f != 0 and ch not in self.goto[f]:
                    f = self.fail[f]
                self.fail[s] = self.goto[f].get(ch, 0)
                if self.fail[s] == s:
                    self.fail[s] = 0

                # 출력 링크 병합 (suffix 매칭 전파)
                self.output[s] |= self.output[self.fail[s]]

    def search(self, text: str):
        """
        텍스트에서 모든 패턴 매칭 위치를 순서대로 yield.
        yield: (start: int, end: int, word: str)
        """
        state = 0
        for i, ch in enumerate(text):
            while state != 0 and ch not in self.goto[state]:
                state = self.fail[state]
            state = self.goto[state].get(ch, 0)
            for word in self.output[state]:
                start = i - len(word) + 1
                yield start, i, word


# ── 전역 상태 ─────────────────────────────────────────────────────────────────

_bad_words: Set[str] = set()
_automaton: Optional[_AhoCorasick] = None  # 빌드 완료 후 교체 (원자적)


def _rebuild_automaton(words: Set[str]) -> _AhoCorasick:
    """단어 집합으로 새 자동마톤을 빌드해 반환한다."""
    ac = _AhoCorasick()
    for w in words:
        ac.add_word(w)
    ac.build()
    return ac


def _is_word_boundary(text: str, start: int, end: int) -> bool:
    """
    매칭 구간 [start, end]의 앞뒤가 단어 경계인지 확인한다.
    영숫자·언더스코어가 아닌 문자(공백, 구두점, 한글 등) 또는 텍스트 양 끝이면 경계.
    → 'hell' ⊂ 'hello' 오탐 방지
    """
    _WORD_CHARS = frozenset('abcdefghijklmnopqrstuvwxyz0123456789_')
    before_ok = (start == 0) or (text[start - 1] not in _WORD_CHARS)
    after_ok  = (end == len(text) - 1) or (text[end + 1] not in _WORD_CHARS)
    return before_ok and after_ok


# ── 파싱 ─────────────────────────────────────────────────────────────────────

def _parse_csv(text: str) -> Set[str]:
    words: Set[str] = set()
    reader = csv.reader(io.StringIO(text))
    next(reader, None)
    for row in reader:
        if row:
            word = row[0].strip().lower()
            if word:
                words.add(word)
    return words


def _parse_txt(text: str) -> Set[str]:
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
        words |= _parse_txt(_LOCAL_TXT.read_text(encoding="utf-8"))
        logger.info(f"[profanity] 로컬 TXT 로드 후 총 {len(words)}개")
    except Exception as e:
        logger.warning(f"[profanity] 로컬 TXT 로드 실패: {e}")
    return words


# ── GitHub fetch ──────────────────────────────────────────────────────────────

async def _fetch_from_github() -> Set[str]:
    words: Set[str] = set()
    async with httpx.AsyncClient(timeout=30) as client:
        try:
            resp = await client.get(_SLANG_CSV_URL)
            if resp.status_code == 200:
                words |= _parse_csv(resp.text)
                logger.info(f"[profanity] GitHub CSV fetch 완료: {len(words)}개")
        except Exception as e:
            logger.warning(f"[profanity] GitHub CSV fetch 실패: {e}")
        try:
            resp = await client.get(_LOL_TXT_URL)
            if resp.status_code == 200:
                words |= _parse_txt(resp.text)
                logger.info(f"[profanity] GitHub TXT fetch 후 총 {len(words)}개")
        except Exception as e:
            logger.warning(f"[profanity] GitHub TXT fetch 실패: {e}")
    return words


# ── 갱신 ─────────────────────────────────────────────────────────────────────

def _apply_words(words: Set[str]) -> None:
    """단어 집합을 전역에 적용하고 자동마톤을 재빌드한다."""
    global _bad_words, _automaton
    _bad_words = words
    _automaton = _rebuild_automaton(words)
    logger.info(f"[profanity] 자동마톤 빌드 완료 — {len(words)}개 패턴, "
                f"{len(_automaton.goto)}개 상태")


async def refresh() -> None:
    """GitHub에서 최신 금칙어 목록을 fetch해 갱신. 실패 시 기존 유지."""
    fetched = await _fetch_from_github()
    if fetched:
        _apply_words(fetched)
    else:
        logger.warning("[profanity] GitHub fetch 결과 없음 — 기존 목록 유지")


async def start_auto_refresh(interval_seconds: int = _REFRESH_INTERVAL) -> None:
    """서버 시작 시 로컬 파일 로드 → GitHub fetch → 주기적 갱신"""
    # 1단계: 로컬 폴백 (즉시)
    _apply_words(_load_local())

    # 2단계: GitHub 최신본 (비동기, 로컬보다 더 많으면 교체)
    await refresh()

    # 3단계: 주기적 갱신
    while True:
        await asyncio.sleep(interval_seconds)
        await refresh()


# ── 공개 API ─────────────────────────────────────────────────────────────────

def contains_profanity(text: str) -> bool:
    """
    텍스트에 금칙어가 포함되어 있으면 True.

    - Aho-Corasick 자동마톤으로 O(n) 단일 패스 검사
    - 단어 경계 확인으로 'hell' ⊂ 'hello' 오탐 방지
    - 자동마톤 미초기화 시 안전하게 False 반환
    """
    if not text or _automaton is None:
        return False
    text_lower = text.lower()
    for start, end, _ in _automaton.search(text_lower):
        if _is_word_boundary(text_lower, start, end):
            return True
    return False


def word_count() -> int:
    """현재 로드된 금칙어 수"""
    return len(_bad_words)
