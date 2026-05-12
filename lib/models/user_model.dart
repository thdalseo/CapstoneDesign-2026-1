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
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 백엔드(snake_case) · 로컬(camelCase) 모두 지원
<<<<<<< HEAD
    String str(String key1, [String? key2]) =>
        (json[key1] ?? (key2 != null ? json[key2] : null))?.toString() ?? '';

    List<String> list(String key1, [String? key2]) {
=======
    String _str(String key1, [String? key2]) =>
        (json[key1] ?? (key2 != null ? json[key2] : null))?.toString() ?? '';

    List<String> _list(String key1, [String? key2]) {
>>>>>>> d2950ad090eaefb70e2143adda888c6b6325a3c5
      final raw = json[key1] ?? (key2 != null ? json[key2] : null);
      return (raw as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    }

    return UserModel(
<<<<<<< HEAD
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
=======
      // 백엔드는 int, 로컬 저장은 String
      id: json['id']?.toString() ?? '',
      name: _str('name'),
      country: _str('country'),
      college: _str('college'),
      major: _str('major'),
      year: _str('year'),
      interests: _list('interests'),
      exchangePurposes: _list('exchange_purposes', 'exchangePurposes'),
      personalities: _list('personalities'),
      languages: _list('languages'),
      description: _str('description'),
      email: _str('email'),
>>>>>>> d2950ad090eaefb70e2143adda888c6b6325a3c5
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
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
      );
}
