class UserModel {
  final String id;
  final String name;
  final String country;     // e.g. "🇰🇷 대한민국"
  final String college;     // 단과대
  final String major;       // 학부/학과
  final String year;        // e.g. "3학년"
  final List<String> interests;
  final List<String> exchangePurposes;
  final List<String> personalities;
  final List<String> languages;
  final String description;
  final String email;
  final String? avatarUrl;

  // 매칭 알고리즘 가중치 (합계 = 100)
  final int weightPurpose;
  final int weightInterests;
  final int weightLanguage;
  final int weightPersonality;
  final int weightMajor;
  final int weightYear;
  final int weightNationality;

  const UserModel({
    this.id = '',
    required this.name,
    required this.country,
    required this.college,
    required this.major,
    this.year = '',
    this.interests = const [],
    this.exchangePurposes = const [],
    this.personalities = const [],
    this.languages = const [],
    this.description = '',
    required this.email,
    this.avatarUrl,
    this.weightPurpose = 25,
    this.weightInterests = 20,
    this.weightLanguage = 18,
    this.weightPersonality = 17,
    this.weightMajor = 8,
    this.weightYear = 7,
    this.weightNationality = 5,
  });

  // "🇰🇷 대한민국" → "🇰🇷"
  String get countryFlag => country.split(' ').first;

  // "🇰🇷 대한민국" → "대한민국"
  String get countryName {
    final parts = country.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : country;
  }

  bool get isProfileComplete =>
      year.isNotEmpty &&
      interests.isNotEmpty &&
      exchangePurposes.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'college': college,
        'major': major,
        'year': year,
        'interests': interests,
        'exchangePurposes': exchangePurposes,
        'personalities': personalities,
        'languages': languages,
        'description': description,
        'email': email,
        'avatarUrl': avatarUrl,
        'weightPurpose': weightPurpose,
        'weightInterests': weightInterests,
        'weightLanguage': weightLanguage,
        'weightPersonality': weightPersonality,
        'weightMajor': weightMajor,
        'weightYear': weightYear,
        'weightNationality': weightNationality,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 백엔드(snake_case) · 로컬(camelCase) 모두 지원
    String str(String key1, [String? key2]) =>
        (json[key1] ?? (key2 != null ? json[key2] : null))?.toString() ?? '';

    List<String> list(String key1, [String? key2]) {
      final raw = json[key1] ?? (key2 != null ? json[key2] : null);
      return (raw as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    }

    int intVal(String key1, [String? key2, int def = 0]) {
      final raw = json[key1] ?? (key2 != null ? json[key2] : null);
      return (raw as num?)?.toInt() ?? def;
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: str('name'),
      country: str('country'),
      college: str('college'),
      major: str('major'),
      year: str('year'),
      interests: list('interests'),
      exchangePurposes: list('exchange_purposes', 'exchangePurposes'),
      personalities: list('personalities'),
      languages: list('languages'),
      description: str('description'),
      email: str('email'),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      weightPurpose: intVal('weight_purpose', 'weightPurpose', 25),
      weightInterests: intVal('weight_interests', 'weightInterests', 20),
      weightLanguage: intVal('weight_language', 'weightLanguage', 18),
      weightPersonality: intVal('weight_personality', 'weightPersonality', 17),
      weightMajor: intVal('weight_major', 'weightMajor', 8),
      weightYear: intVal('weight_year', 'weightYear', 7),
      weightNationality: intVal('weight_nationality', 'weightNationality', 5),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? country,
    String? college,
    String? major,
    String? year,
    List<String>? interests,
    List<String>? exchangePurposes,
    List<String>? personalities,
    List<String>? languages,
    String? description,
    String? email,
    String? avatarUrl,
    int? weightPurpose,
    int? weightInterests,
    int? weightLanguage,
    int? weightPersonality,
    int? weightMajor,
    int? weightYear,
    int? weightNationality,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        country: country ?? this.country,
        college: college ?? this.college,
        major: major ?? this.major,
        year: year ?? this.year,
        interests: interests ?? this.interests,
        exchangePurposes: exchangePurposes ?? this.exchangePurposes,
        personalities: personalities ?? this.personalities,
        languages: languages ?? this.languages,
        description: description ?? this.description,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        weightPurpose: weightPurpose ?? this.weightPurpose,
        weightInterests: weightInterests ?? this.weightInterests,
        weightLanguage: weightLanguage ?? this.weightLanguage,
        weightPersonality: weightPersonality ?? this.weightPersonality,
        weightMajor: weightMajor ?? this.weightMajor,
        weightYear: weightYear ?? this.weightYear,
        weightNationality: weightNationality ?? this.weightNationality,
      );
}
