import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class MyPageProfileCard extends StatelessWidget {
  final UserModel? user;

  const MyPageProfileCard({super.key, this.user});

  static const _fallback = UserModel(
    name: '',
    country: '',
    college: '',
    major: '',
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
    final u = user ?? _fallback;
    final subtitle = [
      if (u.college.isNotEmpty) u.college,
      if (u.major.isNotEmpty) u.major,
      if (u.year.isNotEmpty) u.year,
    ].join(' · ');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F0FE),
                  border: Border.all(color: const Color(0xFFD0DCEF), width: 1),
                ),
                child: u.avatarUrl != null
                    ? ClipOval(child: _buildAvatarImage(u.avatarUrl!))
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFFB0C4DE),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                u.name.isNotEmpty ? u.name : '이름 없음',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.verified, size: 14, color: AppTheme.mint),
                  SizedBox(width: 4),
                  Text(
                    '강원대학교 인증 완료',
                    style: TextStyle(fontSize: 12, color: AppTheme.mint),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
