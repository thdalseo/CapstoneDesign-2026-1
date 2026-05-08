import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chatting/chat_room_tile.dart';
import 'chatting_room_screen.dart';

class ChattingScreen extends StatelessWidget {
  final List<MatchUser> users;

  const ChattingScreen({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              const Text(
                '채팅',
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
        users.isEmpty ? _buildEmpty() : _buildList(context),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: users.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 82,
          endIndent: 20,
          color: AppTheme.border,
        ),
        itemBuilder: (context, i) => ChatRoomTile(
          user: users[i],
          unreadCount: i == 0 ? 1 : 0,
          lastMessage: i == 0 ? '같이 이야기 많이 해요!' : '저도 반가워요! 잘 부탁드려요 😄',
          lastMessageTime: i == 0 ? '오전 10:23' : '어제',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChattingRoomScreen(user: users[i]),
            ),
          ),
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
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 채팅방이 없어요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '매칭된 친구의 프로필에서\n채팅 버튼을 눌러 대화를 시작해보세요!',
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
