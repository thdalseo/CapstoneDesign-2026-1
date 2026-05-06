class UserModel {
  final String id;
  final String name;
  final String country;     // e.g. "🇰🇷 대한민국"
  final String college;     // 단과대
  final String major;       // 학부/학과
  final String year;        // e.g. "3학년"
  final List<String> interests;
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
    this.description = '',
    required this.email,
    this.avatarUrl,
  });

  // "🇰🇷 대한민국" → "🇰🇷"
  String get countryFlag => country.split(' ').first;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'college': college,
        'major': major,
        'year': year,
        'interests': interests,
        'description': description,
        'email': email,
        'avatarUrl': avatarUrl,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        country: json['country'] as String? ?? '',
        college: json['college'] as String? ?? '',
        major: json['major'] as String? ?? '',
        year: json['year'] as String? ?? '',
        interests: (json['interests'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        description: json['description'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? country,
    String? college,
    String? major,
    String? year,
    List<String>? interests,
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
        description: description ?? this.description,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
