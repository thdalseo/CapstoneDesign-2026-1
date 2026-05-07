import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MyPageProfileCard extends StatelessWidget {
  const MyPageProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.person, size: 40, color: Color(0xFFB0C4DE)),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '홍길동',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '공과대학 · 컴퓨터공학과',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 4),
              Row(
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
