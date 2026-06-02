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
    required int weightPurpose,
    required int weightInterests,
    required int weightLanguage,
    required int weightPersonality,
    required int weightMajor,
    required int weightYear,
    required int weightNationality,
  }) async {
    if (_useMock) return; // mock 모드에서는 로컬 저장만

    await ApiClient.put(
      '$_usersBase/${Uri.encodeComponent(email)}/weights',
      {
        'weight_purpose': weightPurpose,
        'weight_interests': weightInterests,
        'weight_language': weightLanguage,
        'weight_personality': weightPersonality,
        'weight_major': weightMajor,
        'weight_year': weightYear,
        'weight_nationality': weightNationality,
      },
    );
  }

  // ── 변환 ───────────────────────────────────────────────────────────────────

  static MatchUser _toMatchUser(Map<String, dynamic> json) {
    List<String> lst(String key) =>
        (json[key] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return MatchUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      major: json['major'] as String? ?? '',
      year: json['year'] as String? ?? '',
      interests: lst('interests'),
      languages: lst('languages'),
      description: json['description'] as String? ?? '',
      matchPercent: (json['match_score'] as num?)?.toInt() ?? 0,
    );
  }

  // ── 샘플 데이터 (seed_data.py 와 같은 순서) ─────────────────────────────────

  static const List<MatchUser> _mockMatches = [
    MatchUser(
      id: '2',
      name: 'Sofia',
      country: '🇺🇸',
      major: '경영학과',
      year: '2학년',
      interests: ['여행', '카페 탐방', '영화'],
      languages: ['영어', '한국어'],
      description: '한국어 공부 중이에요! 같이 언어 교환해요',
      matchPercent: 94,
    ),
    MatchUser(
      id: '3',
      name: 'Liam',
      country: '🇬🇧',
      major: '컴퓨터공학과',
      year: '3학년',
      interests: ['게임', '음악', 'K-POP'],
      languages: ['영어', '한국어'],
      description: '한국 문화와 코딩 공부에 관심이 많아요',
      matchPercent: 91,
    ),
    MatchUser(
      id: '4',
      name: 'Amara',
      country: '🇳🇬',
      major: '국제학부',
      year: '1학년',
      interests: ['요리', '운동', '사진'],
      languages: ['영어'],
      description: '캠퍼스 생활을 배우며 친구를 만들고 싶어요',
      matchPercent: 86,
    ),
    MatchUser(
      id: '5',
      name: 'Yuki',
      country: '🇯🇵',
      major: '일어일문학과',
      year: '2학년',
      interests: ['독서', '드라마', '음악'],
      languages: ['일본어', '한국어', '영어'],
      description: '한국 드라마와 한국어를 같이 배우고 싶어요',
      matchPercent: 83,
    ),
    MatchUser(
      id: '6',
      name: 'Marco',
      country: '🇮🇹',
      major: '체육교육과',
      year: '4학년',
      interests: ['스포츠', '여행', '요리'],
      languages: ['이탈리아어', '영어'],
      description: '축구와 한국 음식을 좋아해요',
      matchPercent: 78,
    ),
    MatchUser(
      id: '7',
      name: '김민지',
      country: '🇰🇷',
      major: '컴퓨터공학과',
      year: '3학년',
      interests: ['게임', 'K-POP', '카페 탐방'],
      languages: ['한국어', '영어'],
      description: '코딩 공부와 언어 교환을 같이 하고 싶어요',
      matchPercent: 89,
    ),
    MatchUser(
      id: '8',
      name: '박재현',
      country: '🇰🇷',
      major: '경영학과',
      year: '2학년',
      interests: ['카페 탐방', '영화', '패션'],
      languages: ['한국어', '영어'],
      description: '발표 연습과 카페 탐방을 좋아해요',
      matchPercent: 82,
    ),
    MatchUser(
      id: '9',
      name: '이서아',
      country: '🇰🇷',
      major: '영어영문학과',
      year: '4학년',
      interests: ['영화', '독서', '언어'],
      languages: ['한국어', '영어', '일본어'],
      description: '영어 회화와 영화 이야기를 나누고 싶어요',
      matchPercent: 88,
    ),
    MatchUser(
      id: '10',
      name: '최도윤',
      country: '🇰🇷',
      major: '컴퓨터공학과',
      year: '1학년',
      interests: ['게임', 'K-POP', '음악'],
      languages: ['한국어', '영어'],
      description: '게임과 K-POP 이야기할 친구를 찾아요',
      matchPercent: 75,
    ),
    MatchUser(
      id: '11',
      name: '정유나',
      country: '🇰🇷',
      major: '행정학과',
      year: '2학년',
      interests: ['여행', '사진', '드라마'],
      languages: ['한국어', '영어'],
      description: '캠퍼스 생활 정보를 나누고 싶어요',
      matchPercent: 80,
    ),
    MatchUser(
      id: '12',
      name: '강현우',
      country: '🇰🇷',
      major: '체육교육과',
      year: '4학년',
      interests: ['운동', '스포츠', '여행'],
      languages: ['한국어'],
      description: '운동 같이 하고 한국 문화를 알려줄게요',
      matchPercent: 77,
    ),
    MatchUser(
      id: '13',
      name: '오수진',
      country: '🇰🇷',
      major: '디자인학과',
      year: '3학년',
      interests: ['사진', '패션', '뷰티'],
      languages: ['한국어', '영어'],
      description: '사진과 전시 보러 다니는 걸 좋아해요',
      matchPercent: 73,
    ),
    MatchUser(
      id: '14',
      name: '한지호',
      country: '🇰🇷',
      major: '간호학과',
      year: '1학년',
      interests: ['독서'],
      languages: ['한국어'],
      description: '의료 용어와 학교 생활을 같이 공부해요',
      matchPercent: 69,
    ),
    MatchUser(
      id: '15',
      name: 'Ethan',
      country: '🇺🇸',
      major: '기계공학과',
      year: '3학년',
      interests: ['운동', '여행', '스포츠'],
      languages: ['영어', '한국어'],
      description: '운동과 여행을 좋아하는 교환학생이에요',
      matchPercent: 84,
    ),
    MatchUser(
      id: '16',
      name: 'Haruto',
      country: '🇯🇵',
      major: '디자인학과',
      year: '1학년',
      interests: ['사진', '카페 탐방', '패션'],
      languages: ['일본어', '한국어'],
      description: '사진과 카페 탐방을 같이 하고 싶어요',
      matchPercent: 81,
    ),
    MatchUser(
      id: '17',
      name: 'Li Wei',
      country: '🇨🇳',
      major: '경영학과',
      year: '2학년',
      interests: ['독서', '영화', '언어'],
      languages: ['중국어', '한국어', '영어'],
      description: '한국어 과제와 발표 연습을 같이 해요',
      matchPercent: 87,
    ),
    MatchUser(
      id: '18',
      name: 'Chen Yu',
      country: '🇨🇳',
      major: '컴퓨터공학과',
      year: '4학년',
      interests: ['게임', '음악', '언어'],
      languages: ['중국어', '영어'],
      description: '게임 개발과 알고리즘 이야기를 좋아해요',
      matchPercent: 79,
    ),
    MatchUser(
      id: '19',
      name: 'Linh',
      country: '🇻🇳',
      major: '국어국문학과',
      year: '2학년',
      interests: ['드라마', '음악', '요리'],
      languages: ['베트남어', '한국어'],
      description: '한국어 글쓰기와 드라마 이야기를 하고 싶어요',
      matchPercent: 85,
    ),
    MatchUser(
      id: '20',
      name: 'Minh',
      country: '🇻🇳',
      major: '행정학과',
      year: '3학년',
      interests: ['여행', '사진', '운동'],
      languages: ['베트남어', '한국어', '영어'],
      description: '학교 행정 절차를 같이 알아보고 싶어요',
      matchPercent: 76,
    ),
    MatchUser(
      id: '21',
      name: 'Claire',
      country: '🇫🇷',
      major: '미술학과',
      year: '2학년',
      interests: ['영화', '패션', '언어'],
      languages: ['프랑스어', '영어', '한국어'],
      description: '전시와 영화 이야기를 나누고 싶어요',
      matchPercent: 74,
    ),
  ];
}
