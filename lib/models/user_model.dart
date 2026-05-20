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
  final int weightMajor;
  final int weightInterests;
  final int weightPersonality;
  final int weightLanguage;
  final int weightPurpose;
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
    this.weightMajor = 12,
    this.weightInterests = 20,
    this.weightPersonality = 17,
    this.weightLanguage = 18,
    this.weightPurpose = 25,
    this.weightNationality = 8,
  });

  // "🇰🇷 대한민국" → "🇰🇷"
  String get countryFlag => country.split(' ').first;

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
        'weightMajor': weightMajor,
        'weightInterests': weightInterests,
        'weightPersonality': weightPersonality,
        'weightLanguage': weightLanguage,
        'weightPurpose': weightPurpose,
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
      weightMajor: intVal('weight_major', 'weightMajor', 12),
      weightInterests: intVal('weight_interests', 'weightInterests', 20),
      weightPersonality: intVal('weight_personality', 'weightPersonality', 17),
      weightLanguage: intVal('weight_language', 'weightLanguage', 18),
      weightPurpose: intVal('weight_purpose', 'weightPurpose', 25),
      weightNationality: intVal('weight_nationality', 'weightNationality', 8),
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
    int? weightMajor,
    int? weightInterests,
    int? weightPersonality,
    int? weightLanguage,
    int? weightPurpose,
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
        weightMajor: weightMajor ?? this.weightMajor,
        weightInterests: weightInterests ?? this.weightInterests,
        weightPersonality: weightPersonality ?? this.weightPersonality,
        weightLanguage: weightLanguage ?? this.weightLanguage,
        weightPurpose: weightPurpose ?? this.weightPurpose,
        weightNationality: weightNationality ?? this.weightNationality,
      );
}
