import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class MyProfileCard extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onTap;

  const MyProfileCard({super.key, required this.user, this.onTap});

  static const _dummy = UserModel(
    name: '홍길동',
    country: '🇰🇷 대한민국',
    college: '공과대학',
    major: '컴퓨터공학과',
    year: '4학년',
    interests: ['여행', '카페탐방', '영화'],
    email: '',
  );

  static Widget _buildAvatarImage(String url) {
    if (kIsWeb || url.startsWith('http') || url.startsWith('blob:')) {
      return Image.network(url, fit: BoxFit.cover);
    }
    return Image.file(File(url), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final u = user ?? _dummy;
    final subtitle = [u.major, if (u.year.isNotEmpty) u.year].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아바타
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F0FE),
            ),
            child: u.avatarUrl != null
                ? ClipOval(child: _buildAvatarImage(u.avatarUrl!))
                : const Icon(
                    Icons.person_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 14),

          // 이름 / 학과·학년 / 관심사
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름 + 국기
                Row(
                  children: [
                    Text(
                      u.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (u.countryFlag.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Text(
                        u.countryFlag,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                if (u.interests.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    children: u.interests.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // 편집 버튼
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
      ),
    );
  }
}
