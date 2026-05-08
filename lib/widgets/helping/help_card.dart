import 'package:flutter/material.dart';
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

  static const Map<String, Color> _categoryColors = {
    '수업': Color(0xFF4C80AF),
    '행정': Color(0xFF8B5CF6),
    '생활': Color(0xFF10B981),
    '언어': Color(0xFFEF4444),
    '한국어': Color(0xFFEF4444),
    '캠퍼스': Color(0xFFF59E0B),
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
                    _badge(category, catColor),
                    if (isUrgent) ...[
                      const SizedBox(width: 6),
                      _badge('긴급', const Color(0xFFEF4444)),
                    ],
                    if (isCompleted) ...[
                      const SizedBox(width: 6),
                      _badge('완료', AppTheme.textSecondary),
                    ],
                    const Spacer(),
                    if (helperCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '도움 $helperCount명',
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
                const SizedBox(height: 8),

                // 작성자
                Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        (widget.post['authorName'] as String? ?? '?')
                            .substring(0, 1),
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
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            _infoRow(Icons.place_outlined,
                                widget.post['place'] as String? ?? ''),
                            const SizedBox(height: 4),
                            _infoRow(Icons.calendar_today_outlined,
                                widget.post['date'] as String? ?? ''),
                            const SizedBox(height: 4),
                            _infoRow(Icons.access_time_outlined,
                                widget.post['time'] as String? ?? ''),
                            if (memo.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                memo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isMyPost && !isCompleted) ...[
                                  _actionBtn('완료', AppTheme.mint,
                                      widget.onComplete),
                                  const SizedBox(width: 8),
                                  _actionBtn('수정', AppTheme.primary,
                                      widget.onEdit),
                                  const SizedBox(width: 8),
                                  _actionBtn('삭제', AppTheme.coral,
                                      widget.onDelete),
                                ] else if (!isMyPost && !isCompleted) ...[
                                  _actionBtn(
                                      '도움주기', AppTheme.mint, widget.onHelp),
                                ],
                              ],
                            ),
                          ],
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
          style:
              const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
              color: widget.color.withValues(alpha: _hovered ? 0.5 : 0.35),
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
