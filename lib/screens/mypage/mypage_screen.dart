import 'package:easy_localization/easy_localization.dart';
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
import 'match_weight_screen.dart';

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
        title: Text(
          'mypage.title'.tr(),
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
              title: 'mypage.section_profile'.tr(),
              items: [
                MyPageMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'mypage.edit_profile'.tr(),
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
                MyPageMenuItem(
                  icon: Icons.tune_rounded,
                  label: 'mypage.match_weight'.tr(),
                  onTap: () async {
                    if (_user == null) return;
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MatchWeightScreen(user: _user!),
                      ),
                    );
                    if (saved == true) _loadUser();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            MyPageSection(
              title: 'mypage.section_app'.tr(),
              items: [
                MyPageMenuItem(
                  icon: Icons.language_outlined,
                  label: 'mypage.language'.tr(),
                  currentValue: context.locale.languageCode == 'ko'
                      ? '한국어'
                      : 'English',
                  onTap: () => _showLanguagePicker(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MyPageSection(
              title: 'mypage.section_account'.tr(),
              items: [
                MyPageMenuItem(
                  icon: Icons.logout,
                  label: 'mypage.logout'.tr(),
                  onTap: () => _showLogoutDialog(context),
                ),
                MyPageMenuItem(
                  icon: Icons.person_remove_outlined,
                  label: 'mypage.delete_account'.tr(),
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

  void _showLanguagePicker(BuildContext context) {
    final languages = [
      {'locale': const Locale('ko'), 'label': '한국어', 'flag': '🇰🇷'},
      {'locale': const Locale('en'), 'label': 'English', 'flag': '🇺🇸'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final currentCode = context.locale.languageCode;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'mypage.language'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...languages.map((lang) {
                  final locale = lang['locale'] as Locale;
                  final isSelected = locale.languageCode == currentCode;
                  return InkWell(
                    onTap: () {
                      context.setLocale(locale);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Text(
                            lang['flag'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            lang['label'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_rounded,
                                color: AppTheme.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'mypage.logout_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: Text('mypage.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: AppTheme.textSecondary)),
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
            child: Text('mypage.logout'.tr(),
                style: const TextStyle(color: AppTheme.primary)),
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
          title: Text(
            'mypage.delete_account_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'mypage.delete_account_desc'.tr(),
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  hintText: 'mypage.password_hint'.tr(),
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
              child: Text('common.cancel'.tr(),
                  style: const TextStyle(color: AppTheme.textSecondary)),
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
              child: Text('mypage.withdraw'.tr(),
                  style: TextStyle(color: Colors.red.shade400)),
            ),
          ],
        ),
      ),
    );
  }
}
