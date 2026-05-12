import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mypage/mypage_profile_card.dart';
import '../../widgets/mypage/mypage_section.dart';
import '../../widgets/mypage/mypage_menu_item.dart';
import '../onboarding/onboarding_screen.dart';
import 'edit_profile_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService.loadUser();
    if (mounted) setState(() => _user = user);
  }

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
            MyPageProfileCard(user: _user),
            const SizedBox(height: 12),
            MyPageSection(
              title: '프로필 설정',
              items: [
                MyPageMenuItem(
                  icon: Icons.edit_outlined,
                  label: '프로필 편집',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: _user),
                      ),
                    );
                    _loadUser();
                  },
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
            onPressed: () async {
              Navigator.pop(context);
              await UserService.clearUser();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (_) => false,
              );
            },
            child: const Text('로그아웃', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool passwordVisible = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '회원탈퇴',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '탈퇴하면 모든 데이터가 삭제되며\n복구할 수 없어요.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  hintText: '비밀번호 입력',
                  hintStyle: const TextStyle(fontSize: 13),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => setDialogState(() => passwordVisible = !passwordVisible),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('취소', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final password = passwordController.text;
                final email = _user?.email ?? '';
                if (password.isEmpty) return;

                Navigator.pop(ctx);

                try {
                  await AuthService.deleteAccount(email: email, password: password);
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('서버에 연결할 수 없어요.'),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (_) => false,
                );
              },
              child: Text('탈퇴하기', style: TextStyle(color: Colors.red.shade400)),
            ),
          ],
        ),
      ),
    );
  }
}
