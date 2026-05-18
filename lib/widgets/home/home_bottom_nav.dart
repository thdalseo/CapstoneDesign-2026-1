import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: const Color(0xFFAAAAAA),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: 'nav.home'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.extension_outlined),
          activeIcon: const Icon(Icons.extension),
          label: 'nav.matching'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat_bubble_outline),
          activeIcon: const Icon(Icons.chat_bubble),
          label: 'nav.chat'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.volunteer_activism_outlined),
          activeIcon: const Icon(Icons.volunteer_activism),
          label: 'nav.help'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: 'nav.my'.tr(),
        ),
      ],
    );
  }
}
