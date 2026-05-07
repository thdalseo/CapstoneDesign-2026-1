import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final time = _formatTime(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [
                // 내 메시지: 시간 → 말풍선
                _timeText(time),
                const SizedBox(width: 6),
                _bubble(context, isMe),
              ]
            : [
                // 상대 메시지: 아바타 → 말풍선 → 시간
                _avatar(),
                const SizedBox(width: 8),
                _bubble(context, isMe),
                const SizedBox(width: 6),
                _timeText(time),
              ],
      ),
    );
  }

  Widget _avatar() => Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE8F0FE),
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppTheme.primary,
          size: 16,
        ),
      );

  Widget _bubble(BuildContext context, bool isMe) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.62,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border:
                isMe ? null : Border.all(color: AppTheme.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 14,
              color: isMe ? Colors.white : AppTheme.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      );

  Widget _timeText(String time) => Text(
        time,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.textSecondary,
        ),
      );

  String _formatTime(DateTime dt) {
    final period = dt.hour < 12 ? '오전' : '오후';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    return '$period $hour:$min';
  }
}
