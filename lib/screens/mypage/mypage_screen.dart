import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mypage/mypage_profile_card.dart';
import '../../widgets/mypage/mypage_section.dart';
import '../../widgets/mypage/mypage_menu_item.dart';
import 'edit_profile_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const MyPageProfileCard(),
            const SizedBox(height: 12),
            MyPageSection(
              title: '프로필 설정',
              items: [
                MyPageMenuItem(
                  icon: Icons.edit_outlined,
                  label: '프로필 편집',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MyPageSection(
              title: '앱 설정',
              items: [
                MyPageMenuItem(
                  icon: Icons.language_outlined,
                  label: '언어 변경',
                  onTap: () {
                    // TODO: 언어 변경 기능 구현
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            MyPageSection(
              title: '계정',
              items: [
                MyPageMenuItem(
                  icon: Icons.logout,
                  label: '로그아웃',
                  onTap: () => _showLogoutDialog(context),
                ),
                MyPageMenuItem(
                  icon: Icons.person_remove_outlined,
                  label: '회원탈퇴',
                  onTap: () => _showDeleteAccountDialog(context),
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '로그아웃',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: const Text('정말 로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 로그아웃 처리
            },
            child: const Text('로그아웃', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '회원탈퇴',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: const Text(
          '탈퇴하면 모든 데이터가 삭제되며\n복구할 수 없어요. 정말 탈퇴하시겠어요?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 회원탈퇴 처리
            },
            child: Text('탈퇴하기', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}
