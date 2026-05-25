class MatchUser {
  final String id;
  final String name;
  final String country;
  final String major;
  final String year;
  final List<String> interests;
  final String description;
  final int matchPercent;

  const MatchUser({
    this.id = '',
    required this.name,
    required this.country,
    required this.major,
    required this.year,
    required this.interests,
    required this.description,
    required this.matchPercent,
  });

  // "🇺🇸 미국" → "미국", "🇺🇸" → "" (이모지만 있으면 빈 문자열)
  String get countryName {
    final parts = country.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : '';
  }
}
