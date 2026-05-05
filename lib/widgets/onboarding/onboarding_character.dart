import 'package:flutter/material.dart';

// 온보딩 화면 상단 캐릭터 일러스트
class OnboardingCharacter extends StatelessWidget {
  const OnboardingCharacter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 가운데 건물
          Positioned(
            child: Icon(
              Icons.account_balance,
              size: 48,
              color: const Color(0xFFB5C9E0),
            ),
          ),
          // 왼쪽 캐릭터 (배낭+모자)
          Positioned(
            left: 40,
            child: _buildCharacter(isLeft: true),
          ),
          // 오른쪽 캐릭터 (손 올리기)
          Positioned(
            right: 40,
            child: _buildCharacter(isLeft: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter({required bool isLeft}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 얼굴
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              isLeft ? '😊' : '👋',
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 몸통
        Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            color: isLeft
                ? const Color(0xFF4A90D9)
                : const Color(0xFF5DCAA5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}