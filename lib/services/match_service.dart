import '../core/api_client.dart';
import '../models/match_user.dart';

class MatchService {
  static const _matchingBase = '/api/matching';
  static const _usersBase = '/api/users';

  /// true이면 백엔드 없이 샘플 데이터 반환
  static const bool _useMock = true;

  // ── 매칭 목록 ──────────────────────────────────────────────────────────────

  static Future<List<MatchUser>> fetchMatches(String email) async {
    if (_useMock) return _mockMatches;

    final list = await ApiClient.getList(
      _matchingBase,
      params: {'email': email},
    );
    return list.cast<Map<String, dynamic>>().map(_toMatchUser).toList();
  }

  // ── 가중치 저장 ────────────────────────────────────────────────────────────

  static Future<void> saveWeights(
    String email, {
    required int weightMajor,
    required int weightInterests,
    required int weightPersonality,
    required int weightLanguage,
    required int weightPurpose,
    required int weightNationality,
  }) async {
    if (_useMock) return; // mock 모드에서는 로컬 저장만

    await ApiClient.put(
      '$_usersBase/${Uri.encodeComponent(email)}/weights',
      {
        'weight_major': weightMajor,
        'weight_interests': weightInterests,
        'weight_personality': weightPersonality,
        'weight_language': weightLanguage,
        'weight_purpose': weightPurpose,
        'weight_nationality': weightNationality,
      },
    );
  }

  // ── 변환 ───────────────────────────────────────────────────────────────────

  static MatchUser _toMatchUser(Map<String, dynamic> json) {
    List<String> lst(String key) =>
        (json[key] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return MatchUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      major: json['major'] as String? ?? '',
      year: json['year'] as String? ?? '',
      interests: lst('interests'),
      description: json['description'] as String? ?? '',
      matchPercent: (json['match_score'] as num?)?.toInt() ?? 0,
    );
  }

  // ── 샘플 데이터 (seed_data.py 와 동일한 유저) ────────────────────────────────

  static const List<MatchUser> _mockMatches = [
    MatchUser(
      id: '1',
      name: 'Sofia',
      country: '🇺🇸',
      major: '경영학과',
      year: '2학년',
      interests: ['여행', '카페 탐방', '영화'],
      description: '한국어 공부 중이에요! 같이 언어 교환해요 😊',
      matchPercent: 92,
    ),
    MatchUser(
      id: '2',
      name: 'Liam',
      country: '🇬🇧',
      major: '컴퓨터공학과',
      year: '3학년',
      interests: ['게임', '음악', 'K-POP'],
      description: '한국 문화에 관심이 많아요! 같이 공부도 하고 싶어요 📚',
      matchPercent: 87,
    ),
    MatchUser(
      id: '3',
      name: 'Amara',
      country: '🇳🇬',
      major: '국제학부',
      year: '1학년',
      interests: ['요리', '운동', '사진'],
      description: '캠퍼스 생활 도움이 필요해요! 친하게 지내고 싶어요 😄',
      matchPercent: 81,
    ),
    MatchUser(
      id: '4',
      name: 'Yuki',
      country: '🇯🇵',
      major: '일어일문학과',
      year: '2학년',
      interests: ['독서', '드라마', '음악'],
      description: '한국 드라마를 정말 좋아해요. 한국어도 배우고 싶어요!',
      matchPercent: 76,
    ),
    MatchUser(
      id: '5',
      name: 'Marco',
      country: '🇮🇹',
      major: '체육교육과',
      year: '4학년',
      interests: ['스포츠', '여행', '요리'],
      description: '축구 좋아하시는 분 같이 운동해요! 한국 음식도 너무 맛있어요 🍜',
      matchPercent: 71,
    ),
  ];
}
