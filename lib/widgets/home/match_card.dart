import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../constants/profile_labels.dart';
import '../../models/match_user.dart';
import '../../services/translation_service.dart';
import '../../theme/app_theme.dart';

// 관심사 태그에 순서대로 적용할 색상
const _kTagColors = [
  Color(0xFF4C80AF),
  Color(0xFF3ABBA0),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
];

class MatchCard extends StatefulWidget {
  final MatchUser user;
  final bool isMatched;
  final VoidCallback? onMatchTap;
  final VoidCallback? onChatTap;

  const MatchCard({
    super.key,
    required this.user,
    this.isMatched = false,
    this.onMatchTap,
    this.onChatTap,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  bool _matchHovered = false;
  bool _chatHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _Header(user: widget.user),
            Expanded(
              child: _Body(
                user: widget.user,
                isMatched: widget.isMatched,
                matchHovered: _matchHovered,
                chatHovered: _chatHovered,
                onMatchEnter: () => setState(() => _matchHovered = true),
                onMatchExit: () => setState(() => _matchHovered = false),
                onMatchTap: widget.onMatchTap,
                onChatEnter: () => setState(() => _chatHovered = true),
                onChatExit: () => setState(() => _chatHovered = false),
                onChatTap: widget.onChatTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 헤더 (클린 화이트) ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final MatchUser user;

  const _Header({required this.user});

  void _showReasonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 헤더
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.mint, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'match_card.reason_title'
                          .tr(namedArgs: {'name': user.name}),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.matchPercent}% 매칭',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 이유 목록
            if (user.matchReasons.isEmpty)
              Text(
                'match_card.reason_empty'.tr(),
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              )
            else
              ...user.matchReasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 매칭도 뱃지 + 안내문구 — 탭하면 매칭 이유 바텀시트
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _showReasonSheet(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.mint.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 12, color: AppTheme.mint),
                        const SizedBox(width: 4),
                        Text(
                          '${user.matchPercent}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mint,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.info_outline_rounded,
                            size: 11, color: AppTheme.mint),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 아바타
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F0FE),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.primary, size: 42),
          ),
          const SizedBox(height: 12),

          // 이름 + 국기
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 7),
              Text(user.country,
                  style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 4),

          // 학과 · 학년
          Text(
            '${user.major} · ${user.year}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 바디 ──────────────────────────────────────────────────────────────────────

class _Body extends StatefulWidget {
  final MatchUser user;
  final bool isMatched;
  final bool matchHovered;
  final bool chatHovered;
  final VoidCallback? onMatchTap;
  final VoidCallback? onMatchEnter;
  final VoidCallback? onMatchExit;
  final VoidCallback? onChatTap;
  final VoidCallback? onChatEnter;
  final VoidCallback? onChatExit;

  const _Body({
    required this.user,
    required this.isMatched,
    required this.matchHovered,
    required this.chatHovered,
    this.onMatchTap,
    this.onMatchEnter,
    this.onMatchExit,
    this.onChatTap,
    this.onChatEnter,
    this.onChatExit,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _isTranslating = false;
  String? _translatedDesc;
  bool _showTranslation = false;

  Future<void> _onTranslateTap() async {
    if (_showTranslation) {
      setState(() => _showTranslation = false);
      return;
    }
    if (_translatedDesc != null) {
      setState(() => _showTranslation = true);
      return;
    }
    setState(() => _isTranslating = true);
    try {
      final targetLang = context.locale.languageCode;
      final result = await TranslationService.translate(
        widget.user.description,
        targetLang: targetLang,
      );
      if (mounted) {
        setState(() {
          _translatedDesc = result;
          _showTranslation = true;
          _isTranslating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final interestLabel = interestLabelOf(locale);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 관심사 태그 (색상 구분)
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children:
                widget.user.interests.take(3).toList().asMap().entries.map((e) {
              final color = _kTagColors[e.key % _kTagColors.length];
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: color.withValues(alpha: 0.22)),
                ),
                child: Text(
                  interestLabel(e.value),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // 자기소개
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textPrimary,
                      height: 1.7,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_showTranslation && _translatedDesc != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.translate_rounded,
                              size: 12, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _translatedDesc!,
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
                  ],
                ],
              ),
            ),
          ),
          // 번역 버튼 (Expanded 밖)
          const SizedBox(height: 6),
          GestureDetector(
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
                          ? 'chat.hide_post_translation'.tr()
                          : 'chat.translate_post'.tr(),
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
          ),
          const SizedBox(height: 10),

          // 버튼 영역
          if (widget.onChatTap != null)
            Row(
              children: [
                Expanded(child: _chatButton(context)),
                const SizedBox(width: 8),
                _matchIconButton(context),
              ],
            )
          else
            _matchFullButton(context),
        ],
      ),
    );
  }

  Widget _matchFullButton(BuildContext context) {
    final active = widget.isMatched || widget.matchHovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onMatchEnter?.call(),
      onExit: (_) => widget.onMatchExit?.call(),
      child: GestureDetector(
        onTap: widget.onMatchTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppTheme.primary : AppTheme.border,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isMatched ? Icons.extension : Icons.extension_outlined,
                size: 18,
                color: active ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isMatched
                    ? 'match_card.matched'.tr()
                    : 'match_card.match'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onChatEnter?.call(),
      onExit: (_) => widget.onChatExit?.call(),
      child: GestureDetector(
        onTap: widget.onChatTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            color: widget.chatHovered ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.chatHovered ? AppTheme.primary : AppTheme.border,
            ),
            boxShadow: widget.chatHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.chatHovered
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 17,
                color: widget.chatHovered ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'match_card.chat'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.chatHovered ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchIconButton(BuildContext context) {
    final active = widget.isMatched || widget.matchHovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onMatchEnter?.call(),
      onExit: (_) => widget.onMatchExit?.call(),
      child: GestureDetector(
        onTap: widget.onMatchTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Icon(
            widget.isMatched ? Icons.extension : Icons.extension_outlined,
            size: 20,
            color: active ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
