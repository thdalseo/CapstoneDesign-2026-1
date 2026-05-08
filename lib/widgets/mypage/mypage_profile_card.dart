import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class MyPageProfileCard extends StatefulWidget {
  const MyPageProfileCard({super.key});

  @override
  State<MyPageProfileCard> createState() => _MyPageProfileCardState();
}

class _MyPageProfileCardState extends State<MyPageProfileCard> {
  // TODO: 백엔드 API 연동 시 UserService.fetchProfile(accessToken) 으로 교체
  static const _fallback = UserModel(
    name: '홍길동',
    country: '🇰🇷 대한민국',
    college: '공과대학',
    major: '컴퓨터공학과',
    year: '4학년',
    email: '',
  );

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await UserService.loadUser();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final u = _user ?? _fallback;
    final subtitle = [
      if (u.college.isNotEmpty) u.college,
      u.major,
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
                    ? ClipOval(
                        child:
                            Image.network(u.avatarUrl!, fit: BoxFit.cover),
                      )
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
                  child: const Icon(
                      Icons.camera_alt, size: 11, color: Colors.white),
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
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
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
