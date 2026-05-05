import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';

class BridgeApp extends StatelessWidget {
  const BridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}