import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EmailVerifyScreen extends StatelessWidget {
  final String email;

  const EmailVerifyScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 72,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              '인증 메일을 발송했어요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '위 메일로 발송된 인증 링크를\n클릭하면 가입이 완료돼요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            // 메일 재발송
            TextButton(
              onPressed: () {
                // TODO: 재발송 API 연동
              },
              child: const Text(
                '인증 메일 다시 받기',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}