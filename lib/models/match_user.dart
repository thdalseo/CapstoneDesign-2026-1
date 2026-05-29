class MatchUser {
  final String id;
  final String name;
  final String country;
  final String major;
  final String year;
  final List<String> interests;
  final String description;
  final int matchPercent;
  final List<String> matchReasons;

  const MatchUser({
    this.id = '',
    required this.name,
    required this.country,
    required this.major,
    required this.year,
    required this.interests,
    required this.description,
    required this.matchPercent,
    this.matchReasons = const [],
  });

  MatchUser copyWith({List<String>? matchReasons}) => MatchUser(
        id: id,
        name: name,
        country: country,
        major: major,
        year: year,
        interests: interests,
        description: description,
        matchPercent: matchPercent,
        matchReasons: matchReasons ?? this.matchReasons,
      );

  // "🇺🇸 미국" → "미국", "🇺🇸" → "" (이모지만 있으면 빈 문자열)
  String get countryName {
    final parts = country.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : '';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'major': major,
        'year': year,
        'interests': interests,
        'description': description,
        'matchPercent': matchPercent,
        'matchReasons': matchReasons,
      };

  factory MatchUser.fromJson(Map<String, dynamic> json) => MatchUser(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        country: json['country'] as String? ?? '',
        major: json['major'] as String? ?? '',
        year: json['year'] as String? ?? '',
        interests: (json['interests'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        description: json['description'] as String? ?? '',
        matchPercent: json['matchPercent'] as int? ?? 0,
        matchReasons: (json['matchReasons'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}
