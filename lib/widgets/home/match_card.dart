import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';

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
  bool _puzzleHovered = false;
  bool _chatHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final profileH = constraints.maxHeight / 3;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 프로필 섹션 (카드 높이 1/3) ──
                SizedBox(
                  height: profileH,
                  child: Container(
                    color: const Color(0xFFF7F9FC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        // 프로필 이미지 (고정 크기)
                        Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE8F0FE),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppTheme.primary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 이름 · 학과 · 학년
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.user.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.user.country,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.user.major,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.user.year,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 구분선 ──
                Container(height: 1, color: const Color(0xFFEEF2F7)),

                // ── 하단 (2/3): 뱃지 · 자기소개 · 매칭도+버튼 ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 취미 뱃지 3개
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.user.interests.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // 자기소개
                        Text(
                          widget.user.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                            height: 1.7,
                          ),
                        ),
                        const Spacer(),

                        // 매칭도 + 버튼들
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 15,
                                  color: AppTheme.mint,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '매칭도 ${widget.user.matchPercent}%',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.mint,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // 채팅 버튼
                                if (widget.onChatTap != null)
                                  MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _chatHovered = true),
                                    onExit: (_) =>
                                        setState(() => _chatHovered = false),
                                    child: GestureDetector(
                                      onTap: widget.onChatTap,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: _chatHovered
                                              ? AppTheme.primary
                                              : const Color(0xFFF0F4F8),
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          boxShadow: _chatHovered
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primary
                                                        .withValues(alpha: 0.30),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          _chatHovered
                                              ? Icons.chat_bubble_rounded
                                              : Icons.chat_bubble_outline_rounded,
                                          size: 22,
                                          color: _chatHovered
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (widget.onChatTap != null)
                                  const SizedBox(width: 8),
                                // 퍼즐(매칭) 버튼
                                MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _puzzleHovered = true),
                                  onExit: (_) =>
                                      setState(() => _puzzleHovered = false),
                                  child: GestureDetector(
                                    onTap: widget.onMatchTap,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: _puzzleHovered
                                            ? AppTheme.primary
                                            : widget.isMatched
                                                ? AppTheme.primary
                                                    .withValues(alpha: 0.12)
                                                : const Color(0xFFF0F4F8),
                                        borderRadius: BorderRadius.circular(13),
                                        boxShadow: _puzzleHovered
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.primary
                                                      .withValues(alpha: 0.30),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        widget.isMatched || _puzzleHovered
                                            ? Icons.extension
                                            : Icons.extension_outlined,
                                        size: 22,
                                        color: _puzzleHovered
                                            ? Colors.white
                                            : widget.isMatched
                                                ? AppTheme.primary
                                                : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
