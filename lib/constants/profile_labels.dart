/// 프로필 칩(관심사·성향·언어·교류목적) 다국어 라벨 맵
/// DB에 한국어로 저장되어 있으므로 한국어 키 → 각 언어 번역값으로 구성
library;

// ── 관심사 ─────────────────────────────────────────────────────────────────────

const Map<String, String> interestLabelsEn = {
  '여행': 'Travel',
  '카페 탐방': 'Cafes',
  '영화': 'Movies',
  '음악': 'Music',
  '운동': 'Exercise',
  'K-POP': 'K-POP',
  '요리': 'Cooking',
  '사진': 'Photography',
  '독서': 'Reading',
  '게임': 'Gaming',
  '드라마': 'Drama',
  '패션': 'Fashion',
  '뷰티': 'Beauty',
  '스포츠': 'Sports',
  '언어': 'Language',
};

const Map<String, String> interestLabelsZh = {
  '여행': '旅行',
  '카페 탐방': '咖啡探店',
  '영화': '电影',
  '음악': '音乐',
  '운동': '健身',
  'K-POP': 'K-POP',
  '요리': '烹饪',
  '사진': '摄影',
  '독서': '阅读',
  '게임': '游戏',
  '드라마': '韩剧',
  '패션': '时尚',
  '뷰티': '美妆',
  '스포츠': '体育运动',
  '언어': '语言',
};

const Map<String, String> interestLabelsVi = {
  '여행': 'Du lịch',
  '카페 탐방': 'Khám phá quán cà phê',
  '영화': 'Phim ảnh',
  '음악': 'Âm nhạc',
  '운동': 'Tập thể dục',
  'K-POP': 'K-POP',
  '요리': 'Nấu ăn',
  '사진': 'Chụp ảnh',
  '독서': 'Đọc sách',
  '게임': 'Trò chơi',
  '드라마': 'Phim truyền hình',
  '패션': 'Thời trang',
  '뷰티': 'Làm đẹp',
  '스포츠': 'Thể thao',
  '언어': 'Ngôn ngữ',
};

const Map<String, String> interestLabelsJa = {
  '여행': '旅行',
  '카페 탐방': 'カフェ巡り',
  '영화': '映画',
  '음악': '音楽',
  '운동': '運動',
  'K-POP': 'K-POP',
  '요리': '料理',
  '사진': '写真',
  '독서': '読書',
  '게임': 'ゲーム',
  '드라마': 'ドラマ',
  '패션': 'ファッション',
  '뷰티': 'ビューティー',
  '스포츠': 'スポーツ',
  '언어': '言語',
};

// ── 성향 ─────────────────────────────────────────────────────────────────────

const Map<String, String> personalityLabelsEn = {
  '외향적': 'Extrovert',
  '내향적': 'Introvert',
  '친화적': 'Sociable',
  '차분한': 'Calm',
  '계획적인': 'Organized',
  '유쾌한': 'Cheerful',
  '진지한': 'Serious',
  '활발한': 'Active',
  '감성적인': 'Emotional',
  '호기심 많은': 'Curious',
};

const Map<String, String> personalityLabelsZh = {
  '외향적': '外向',
  '내향적': '内向',
  '친화적': '友善',
  '차분한': '沉稳',
  '계획적인': '有条理',
  '유쾌한': '开朗',
  '진지한': '认真',
  '활발한': '活泼',
  '감성적인': '感性',
  '호기심 많은': '好奇心强',
};

const Map<String, String> personalityLabelsVi = {
  '외향적': 'Hướng ngoại',
  '내향적': 'Hướng nội',
  '친화적': 'Thân thiện',
  '차분한': 'Điềm tĩnh',
  '계획적인': 'Có kế hoạch',
  '유쾌한': 'Vui vẻ',
  '진지한': 'Nghiêm túc',
  '활발한': 'Năng động',
  '감성적인': 'Giàu cảm xúc',
  '호기심 많은': 'Tò mò',
};

const Map<String, String> personalityLabelsJa = {
  '외향적': '外向的',
  '내향적': '内向的',
  '친화적': '社交的',
  '차분한': '穏やか',
  '계획적인': '計画的',
  '유쾌한': '陽気',
  '진지한': '真剣',
  '활발한': '活発',
  '감성적인': '感情豊か',
  '호기심 많은': '好奇心旺盛',
};

// ── 사용 가능 언어 ──────────────────────────────────────────────────────────────

const Map<String, String> languageLabelsEn = {
  '한국어': 'Korean',
  '영어': 'English',
  '중국어': 'Chinese',
  '일본어': 'Japanese',
  '베트남어': 'Vietnamese',
  '프랑스어': 'French',
  '독일어': 'German',
  '스페인어': 'Spanish',
  '러시아어': 'Russian',
  '아랍어': 'Arabic',
};

const Map<String, String> languageLabelsZh = {
  '한국어': '韩语',
  '영어': '英语',
  '중국어': '中文',
  '일본어': '日语',
  '베트남어': '越南语',
  '프랑스어': '法语',
  '독일어': '德语',
  '스페인어': '西班牙语',
  '러시아어': '俄语',
  '아랍어': '阿拉伯语',
};

const Map<String, String> languageLabelsVi = {
  '한국어': 'Tiếng Hàn',
  '영어': 'Tiếng Anh',
  '중국어': 'Tiếng Trung',
  '일본어': 'Tiếng Nhật',
  '베트남어': 'Tiếng Việt',
  '프랑스어': 'Tiếng Pháp',
  '독일어': 'Tiếng Đức',
  '스페인어': 'Tiếng Tây Ban Nha',
  '러시아어': 'Tiếng Nga',
  '아랍어': 'Tiếng Ả Rập',
};

const Map<String, String> languageLabelsJa = {
  '한국어': '韓国語',
  '영어': '英語',
  '중국어': '中国語',
  '일본어': '日本語',
  '베트남어': 'ベトナム語',
  '프랑스어': 'フランス語',
  '독일어': 'ドイツ語',
  '스페인어': 'スペイン語',
  '러시아어': 'ロシア語',
  '아랍어': 'アラビア語',
};

// ── 교류 목적 ─────────────────────────────────────────────────────────────────

const Map<String, String> purposeLabelsEn = {
  '언어교환': 'Language Exchange',
  '학업도움': 'Academic Help',
  '친구사귀기': 'Making Friends',
  '문화교류': 'Cultural Exchange',
};

const Map<String, String> purposeLabelsZh = {
  '언어교환': '语言交换',
  '학업도움': '学业帮助',
  '친구사귀기': '交朋友',
  '문화교류': '文化交流',
};

const Map<String, String> purposeLabelsVi = {
  '언어교환': 'Trao đổi ngôn ngữ',
  '학업도움': 'Hỗ trợ học tập',
  '친구사귀기': 'Kết bạn',
  '문화교류': 'Giao lưu văn hóa',
};

const Map<String, String> purposeLabelsJa = {
  '언어교환': '言語交換',
  '학업도움': '学業サポート',
  '친구사귀기': '友達作り',
  '문화교류': '文化交流',
};

// ── 공통 헬퍼 ─────────────────────────────────────────────────────────────────

/// 로케일 코드에 맞는 라벨 맵 반환
Map<String, String> _mapForLocale(
  String locale,
  Map<String, String> en,
  Map<String, String> zh,
  Map<String, String> vi,
  Map<String, String> ja,
) {
  return switch (locale) {
    'en' => en,
    'zh' => zh,
    'vi' => vi,
    'ja' => ja,
    _ => const {}, // 'ko' → 빈 맵 (한국어 그대로)
  };
}

/// 관심사 라벨 변환 함수
String Function(String) interestLabelOf(String locale) {
  final map = _mapForLocale(
      locale, interestLabelsEn, interestLabelsZh, interestLabelsVi, interestLabelsJa);
  return (item) => map[item] ?? item;
}

/// 성향 라벨 변환 함수
String Function(String) personalityLabelOf(String locale) {
  final map = _mapForLocale(
      locale, personalityLabelsEn, personalityLabelsZh, personalityLabelsVi, personalityLabelsJa);
  return (item) => map[item] ?? item;
}

/// 사용 언어 라벨 변환 함수
String Function(String) languageLabelOf(String locale) {
  final map = _mapForLocale(
      locale, languageLabelsEn, languageLabelsZh, languageLabelsVi, languageLabelsJa);
  return (item) => map[item] ?? item;
}

/// 교류 목적 라벨 변환 함수
String Function(String) purposeLabelOf(String locale) {
  final map = _mapForLocale(
      locale, purposeLabelsEn, purposeLabelsZh, purposeLabelsVi, purposeLabelsJa);
  return (item) => map[item] ?? item;
}
