import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

class BridgeApp extends StatelessWidget {
  final bool isLoggedIn;

  const BridgeApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // easy_localization이 locale, delegates, supportedLocales를 자동 관리
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      home: isLoggedIn ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
