class MatchUser {
  final String name;
  final String country;
  final String major;
  final String year;
  final List<String> interests;
  final String description;
  final int matchPercent;

  const MatchUser({
    required this.name,
    required this.country,
    required this.major,
    required this.year,
    required this.interests,
    required this.description,
    required this.matchPercent,
  });
}
