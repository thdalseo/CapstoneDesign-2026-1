import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../auth/signup_screen.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isHoveringSignup = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _idController.text.trim();
    final password = _passwordController.text;

    // TODO: 개발 완료 후 아래 주석 해제하고 빈칸 통과 로직 제거
    if (email.isNotEmpty && password.isNotEmpty) {
      setState(() => _isLoading = true);
      final valid = await UserService.checkCredentials(email, password);
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('이메일 또는 비밀번호가 올바르지 않아요'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/onboarding.jpg',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _idController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: '이메일 (아이디)',
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: '비밀번호',
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('로그인'),
                      ),
                      const SizedBox(height: 12),

                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _isHoveringSignup = true),
                        onExit: (_) =>
                            setState(() => _isHoveringSignup = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isHoveringSignup
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Text(
                                '회원가입',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _isHoveringSignup
                                      ? Colors.white
                                      : AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
