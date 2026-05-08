import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;
    final time = _formatTime(widget.message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [
                _timeText(time),
                const SizedBox(width: 6),
                _bubble(context, isMe),
              ]
            : [
                _avatar(),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bubble(context, isMe),
                    const SizedBox(height: 4),
                    _translateButton(),
                  ],
                ),
                const SizedBox(width: 6),
                _timeText(time),
              ],
      ),
    );
  }

  Widget _translateButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _showTranslation = !_showTranslation);
        // TODO: 번역 API 연동
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.translate_rounded,
            size: 12,
            color: _showTranslation ? AppTheme.primary : AppTheme.textSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            _showTranslation ? '번역 닫기' : '번역보기',
            style: TextStyle(
              fontSize: 11,
              color: _showTranslation ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            widget.message.content,
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
