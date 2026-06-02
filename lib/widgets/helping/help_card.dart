import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import '../../theme/app_theme.dart';

class HelpCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHelp;
  final VoidCallback? onComplete;

  const HelpCard({
    super.key,
    required this.post,
    this.onEdit,
    this.onDelete,
    this.onHelp,
    this.onComplete,
  });

  @override
  State<HelpCard> createState() => _HelpCardState();
}

class _HelpCardState extends State<HelpCard> {
  bool _expanded = false;
  bool _isTranslating = false;
  String? _translatedTitle;
  String? _translatedMemo;
  bool _showTranslation = false;

  static const Map<String, Color> _categoryColors = {
    '수업': AppTheme.primary,        // 파스텔 블루
    '행정': Color(0xFFA78BFA),        // 파스텔 라벤더
    '생활': Color(0xFF34D399),       // 파스텔 에메랄드
    '언어': Color(0xFFFC7171),       // 파스텔 로즈
    '한국어': Color(0xFFFC7171),
    '캠퍼스': Color(0xFFFBBF24),     // 파스텔 앰버
    '의료': Color(0xFFF472B6),       // 파스텔 핑크
    '기타': Color(0xFF9CA3AF),       // 라이트 그레이
  };

  // DB 값(한국어) → 번역 키
  static const Map<String, String> _categoryKeys = {
    '생활': 'help.cat_living',
    '수업': 'help.cat_class',
    '언어': 'help.cat_language',
    '의료': 'help.cat_medical',
    '캠퍼스': 'help.cat_campus',
    '행정': 'help.cat_admin',
    '기타': 'help.cat_other',
  };

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.post['isCompleted'] as bool? ?? false;
    final bool isMyPost = widget.post['isMyPost'] as bool? ?? false;
    final bool isUrgent = widget.post['isUrgent'] as bool? ?? false;
    final int helperCount = widget.post['helperCount'] as int? ?? 0;
    final String category = widget.post['category'] as String? ?? '';
    final Color catColor =
        _categoryColors[category] ?? AppTheme.textSecondary;
    final String memo = widget.post['memo'] as String? ?? '';
    final String categoryLabel =
        (_categoryKeys[category] ?? category).tr();

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 배지 + 도움 명수
                Row(
                  children: [
                    _badge(categoryLabel, catColor),
                    if (isUrgent) ...[
                      const SizedBox(width: 6),
                      _badge('help.badge_urgent'.tr(),
                          const Color(0xFFEF4444)),
                    ],
                    if (isCompleted) ...[
                      const SizedBox(width: 6),
                      _badge('help.badge_complete'.tr(),
                          AppTheme.textSecondary),
                    ],
                    const Spacer(),
                    if (helperCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'help.helper_count'.tr(
                              namedArgs: {'count': '$helperCount'}),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 제목
                Text(
                  widget.post['title'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),

                // 번역 결과 (제목 + 메모)
                if (_showTranslation && _translatedTitle != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.translate_rounded,
                                size: 11, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _translatedTitle!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_translatedMemo != null &&
                            _translatedMemo!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _translatedMemo!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // 작성자 행
                Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        _initial(widget.post['authorName'] as String? ?? ''),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.post['authorName'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '· ${widget.post['major'] as String? ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 번역 버튼
                    GestureDetector(
                      onTap: _isTranslating ? null : _onTranslateTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isTranslating)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: AppTheme.primary),
                            )
                          else
                            Icon(Icons.translate_rounded,
                                size: 11,
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
                    const SizedBox(width: 8),
                    Text(
                      widget.post['timeAgo'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                // 펼쳐지는 상세 영역
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 좌측: 장소·날짜·시간·내용 (전체)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow(Icons.place_outlined,
                                        widget.post['place'] as String? ?? ''),
                                    const SizedBox(height: 4),
                                    _infoRow(Icons.calendar_today_outlined,
                                        widget.post['date'] as String? ?? ''),
                                    const SizedBox(height: 4),
                                    _infoRow(Icons.access_time_outlined,
                                        widget.post['time'] as String? ?? ''),
                                    if (memo.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        memo,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 우측 하단: 버튼들 (좌측 전체 높이 기준 하단 정렬)
                              if (!isMyPost && !isCompleted)
                                _actionBtn('help.btn_help'.tr(),
                                    AppTheme.mint, widget.onHelp)
                              else if (isMyPost && !isCompleted)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _actionBtn('help.btn_complete'.tr(),
                                        AppTheme.mint, widget.onComplete),
                                    const SizedBox(width: 6),
                                    _actionBtn('help.btn_edit'.tr(),
                                        AppTheme.primary, widget.onEdit),
                                    const SizedBox(width: 6),
                                    _actionBtn('help.btn_delete'.tr(),
                                        AppTheme.coral, widget.onDelete),
                                  ],
                                ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTranslateTap() async {
    if (_showTranslation) {
      setState(() => _showTranslation = false);
      return;
    }
    if (_translatedTitle != null) {
      setState(() => _showTranslation = true);
      return;
    }
    setState(() => _isTranslating = true);
    try {
      final targetLang = context.locale.languageCode;
      final title = widget.post['title'] as String? ?? '';
      final memo = widget.post['memo'] as String? ?? '';
      final translatedTitle = await TranslationService.translate(
        title,
        targetLang: targetLang,
      );
      final translatedMemo = memo.isNotEmpty
          ? await TranslationService.translate(memo, targetLang: targetLang)
          : '';
      if (mounted) {
        setState(() {
          _translatedTitle = translatedTitle;
          _translatedMemo = translatedMemo;
          _showTranslation = true;
          _isTranslating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  /// 이름 첫 글자 (빈 문자열 안전 처리)
  String _initial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback? onTap) {
    return _HoverActionBtn(label: label, color: color, onTap: onTap);
  }
}

class _HoverActionBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _HoverActionBtn({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_HoverActionBtn> createState() => _HoverActionBtnState();
}

class _HoverActionBtnState extends State<_HoverActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.color.withValues(alpha: _hovered ? 0.5 : 0.35),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
