import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/matching/matched_user_tile.dart';

class MatchingScreen extends StatelessWidget {
  final List<MatchUser> users;
  final void Function(MatchUser) onToggle;
  final void Function(MatchUser) onStartChat;
  /// 이미 채팅방이 열린 유저 ID 집합 (채팅 중 표시용)
  final Set<String> chatUserIds;

  const MatchingScreen({
    super.key,
    required this.users,
    required this.onToggle,
    required this.onStartChat,
    this.chatUserIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              Text(
                'matching.title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (users.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${users.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        users.isEmpty ? _buildEmpty() : _buildList(),
      ],
    );
  }

  Widget _buildList() {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: users.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 78,
          endIndent: 20,
          color: AppTheme.border,
        ),
        itemBuilder: (context, i) => MatchedUserTile(
          user: users[i],
          onToggle: () => onToggle(users[i]),
          onStartChat: () => onStartChat(users[i]),
          isInChat: chatUserIds.contains(users[i].id),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F0FE),
              ),
              child: const Icon(
                Icons.extension_outlined,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'matching.empty_title'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'matching.empty_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
