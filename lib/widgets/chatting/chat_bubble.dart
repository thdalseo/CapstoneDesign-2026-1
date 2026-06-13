import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/translation_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/avatar_color.dart';

/// __LANG_SESSION__ 메시지 파싱 결과
class _SessionData {
  final String teach;
  final String learn;
  final String minutes;
  _SessionData({required this.teach, required this.learn, required this.minutes});

  static _SessionData? tryParse(String content) {
    if (!content.startsWith('__LANG_SESSION__|')) return null;
    final parts = content.split('|');
    if (parts.length < 4) return null;
    try {
      final teach = parts[1].split(':').skip(1).join(':');
      final learn = parts[2].split(':').skip(1).join(':');
      final minutes = parts[3].split(':').skip(1).join(':');
      return _SessionData(teach: teach, learn: learn, minutes: minutes);
    } catch (_) {
      return null;
    }
  }
}

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isRead;
  /// 상대방 이름 (아바타 색상용)
  final String senderName;
  /// 세션 시작 버튼 탭 콜백 (teach, learn, minutes)
  final void Function(String teach, String learn, int minutes)? onSessionStart;
  /// 현재 세션이 진행 중인지 (외부에서 주입 → 카드 UI 동기화)
  final bool isSessionActive;
  /// 세션이 완료되었는지 (카드 버튼 "세션 완료" 표시용)
  final bool isSessionDone;

  const ChatBubble({
    super.key,
    required this.message,
    this.isRead = false,
    this.senderName = '',
    this.onSessionStart,
    this.isSessionActive = false,
    this.isSessionDone = false,
  });

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
    final session = _SessionData.tryParse(widget.message.content);

    // 언어교환 세션 카드 → 별도 렌더링
    if (session != null) {
      return _SessionCard(
        session: session,
        isMe: isMe,
        time: time,
        onStart: widget.onSessionStart,
        isSessionActive: widget.isSessionActive,
        isSessionDone: widget.isSessionDone,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isRead) ...[
                      const Icon(Icons.done_rounded,
                          size: 13, color: AppTheme.textSecondary),
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
            Icon(Icons.translate_rounded,
                size: 12,
                color: _showTranslation
                    ? AppTheme.primary
                    : AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text(
            _isTranslating
                ? 'chat.translating'.tr()
                : _showTranslation
                    ? 'chat.hide_translation'.tr()
                    : 'chat.translate'.tr(),
            style: TextStyle(
              fontSize: 11,
              color: _showTranslation
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
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
          maxWidth: MediaQuery.of(context).size.width * 0.62),
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
                    height: 1.45),
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
          widget.message.content, targetLang: targetLang);
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

  // 이름 기반 색상 아바타
  Widget _avatar() {
    final color = avatarColorFor(widget.senderName);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Text(
          avatarInitial(widget.senderName),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _bubble(BuildContext context, bool isMe) => ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.62),
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
            border: isMe
                ? null
                : Border.all(color: AppTheme.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.message.content.startsWith('__SYS__|')
                ? widget.message.content.substring('__SYS__|'.length)
                : widget.message.content,
            style: TextStyle(
              fontSize: 14,
              color: isMe ? Colors.white : AppTheme.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      );

  Widget _timeText(String time) => Text(time,
      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary));

  String _formatTime(DateTime dt) {
    final period = dt.hour < 12 ? '오전' : '오후';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    return '$period $hour:$min';
  }
}

// ── 언어교환 세션 카드 ──────────────────────────────────────────────────────────

class _SessionCard extends StatefulWidget {
  final _SessionData session;
  final bool isMe;
  final String time;
  final void Function(String teach, String learn, int minutes)? onStart;
  final bool isSessionActive;
  final bool isSessionDone;

  const _SessionCard({
    required this.session,
    required this.isMe,
    required this.time,
    this.onStart,
    this.isSessionActive = false,
    this.isSessionDone = false,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _started = false;

  bool get _isDone => widget.isSessionDone;
  bool get _isRunning => !_isDone && (_started || widget.isSessionActive);

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isMe = widget.isMe;
    final time = widget.time;
    final minutes = int.tryParse(session.minutes) ?? 30;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 발신 방향 라벨
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              isMe ? 'chat.session_sent'.tr() : 'chat.session_received'.tr(),
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          // 카드
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.sessionAccent.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.session.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: const BoxDecoration(
                    color: AppTheme.session,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          size: 16, color: AppTheme.sessionAccent),
                      const SizedBox(width: 6),
                      Text(
                        'chat.session_title'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.sessionAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                // 언어 페어
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _langChip(session.teach,
                          AppTheme.session, AppTheme.sessionAccent),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.swap_horiz_rounded,
                            size: 18,
                            color: AppTheme.sessionAccent),
                      ),
                      _langChip(session.learn,
                          AppTheme.session, AppTheme.sessionAccent),
                    ],
                  ),
                ),
                // 시간
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 13,
                          color: AppTheme.sessionAccent),
                      const SizedBox(width: 5),
                      Text(
                        'chat.session_minutes'
                            .tr(namedArgs: {'n': session.minutes}),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // 세션 시작 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: _isDone
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.emoji_events_rounded,
                                    size: 14, color: AppTheme.primary),
                                const SizedBox(width: 5),
                                Text(
                                  'chat.session_done'.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _isRunning
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: AppTheme.session,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 14, color: AppTheme.sessionAccent),
                                const SizedBox(width: 5),
                                Text(
                                  'chat.session_running'.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.sessionAccent,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              setState(() => _started = true);
                              widget.onStart?.call(
                                  session.teach, session.learn, minutes);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: AppTheme.sessionAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'chat.session_start'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          // 시간 스탬프
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(time,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _langChip(String lang, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        lang,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

