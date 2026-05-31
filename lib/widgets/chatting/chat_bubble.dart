import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/translation_service.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isRead; // 상대방이 읽었는지 여부 (내 메시지에만 적용)

  const ChatBubble({super.key, required this.message, this.isRead = false});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTranslation = false;
  bool _isTranslating = false;
  String? _translatedText;

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
                // 시간 + 읽음 표시 (내 메시지 왼쪽)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isRead) ...[
                      const Icon(
                        Icons.done_rounded,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 2),
                    ],
                    _timeText(time),
                  ],
                ),
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
                    if (_showTranslation && _translatedText != null)
                      _translationBox(context),
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
      onTap: _isTranslating ? null : _onTranslateTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isTranslating)
            const SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AppTheme.primary),
            )
          else
            Icon(
              Icons.translate_rounded,
              size: 12,
              color:
                  _showTranslation ? AppTheme.primary : AppTheme.textSecondary,
            ),
          const SizedBox(width: 3),
          Text(
            _isTranslating
                ? 'chat.translating'.tr()
                : _showTranslation
                    ? 'chat.hide_translation'.tr()
                    : 'chat.translate'.tr(),
            style: TextStyle(
              fontSize: 11,
              color:
                  _showTranslation ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _translationBox(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.62,
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.translate_rounded,
                size: 12, color: AppTheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _translatedText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTranslateTap() async {
    if (_showTranslation && _translatedText != null) {
      setState(() => _showTranslation = false);
      return;
    }
    if (_translatedText != null) {
      setState(() => _showTranslation = true);
      return;
    }
    setState(() => _isTranslating = true);
    try {
      final targetLang = context.locale.languageCode;
      final result = await TranslationService.translate(
        widget.message.content,
        targetLang: targetLang,
      );
      if (mounted) {
        setState(() {
          _translatedText = result;
          _showTranslation = true;
          _isTranslating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isTranslating = false);
    }
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

