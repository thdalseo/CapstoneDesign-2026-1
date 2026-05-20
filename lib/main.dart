import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('zh'),
        Locale('vi'),
        Locale('ja'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      startLocale: const Locale('ko'),
      child: BridgeApp(isLoggedIn: isLoggedIn),
    ),
  );
}
