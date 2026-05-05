import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MatchCard extends StatelessWidget {
  final String name;
  final String country;
  final String major;
  final String year;
  final List<String> interests;
  final String description;
  final int matchPercent;

  const MatchCard({
    super.key,
    required this.name,
    required this.country,
    required this.major,
    required this.year,
    required this.interests,
    required this.description,
    required this.matchPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 영역
          Row(
            children: [
              // 프로필 이미지 공간
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F0FE),
                  border: Border.all(
                    color: const Color(0xFFD0DCEF),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: Color(0xFFB0C4DE),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        country,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$major · $year',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 관심사 칩
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDDE4EE)),
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // 한마디
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),

          // 매칭도
          Text(
            '매칭도 $matchPercent%',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.mint,
            ),
          ),
        ],
      ),
    );
  }
}