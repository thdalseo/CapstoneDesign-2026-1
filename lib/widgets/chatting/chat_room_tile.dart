import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';
import '../../utils/avatar_color.dart';

class ChatRoomTile extends StatelessWidget {
  final MatchUser user;
  final VoidCallback onTap;
  final int unreadCount;
  final String? lastMessage;
  final String? lastMessageTime;

  const ChatRoomTile({
    super.key,
    required this.user,
    required this.onTap,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageTime,
  });

  /// __LANG_REQ__ 포맷 및 특수 메시지 처리
  String _formatPreview(BuildContext context) {
    final msg = lastMessage;
    if (msg == null || msg.isEmpty) return 'chat.room_start_hint'.tr();
    if (msg.startsWith('__LANG_REQ__|')) return '🔤 언어교환 요청';
    if (msg.startsWith('🤝 함께해요!')) return '🤝 도움 요청에 응했어요';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _formatPreview(context);
    final avatarColor = avatarColorFor(user.name);
    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // 아바타 (이름 기반 색상 + 첫 글자)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  avatarInitial(user.name),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 이름 + 마지막 메시지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (user.countryFlag.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Text(
                          user.countryFlag,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 시간 + 읽지 않은 배지
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastMessageTime ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasUnread
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontWeight:
                        hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
