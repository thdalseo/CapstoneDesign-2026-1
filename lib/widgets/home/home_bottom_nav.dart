import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  /// 채팅 탭 읽지 않은 메시지 수 (0이면 뱃지 숨김)
  final int unreadCount;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
  });

  Widget _chatIcon({required bool active}) {
    final icon = active
        ? const Icon(Icons.chat_bubble_rounded)
        : const Icon(Icons.chat_bubble_outline_rounded);

    if (unreadCount <= 0) return icon;

    return Badge(
      label: Text(
        unreadCount > 99 ? '99+' : '$unreadCount',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFFEF4444),
      child: icon,
    );
  }

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
          icon: _chatIcon(active: false),
          activeIcon: _chatIcon(active: true),
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
