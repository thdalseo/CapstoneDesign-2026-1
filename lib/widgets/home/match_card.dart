import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';

class MatchCard extends StatefulWidget {
  final MatchUser user;

  const MatchCard({super.key, required this.user});

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  bool _puzzleHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFE8F0FE),
                              border: Border.all(
                                color: const Color(0xFFD0DCEF),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFFB0C4DE),
                              size: 36,
                            ),
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
                                border: Border.all(
                                  color: const Color(0xFFDDE4EE),
                                ),
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

                        // 매칭도 + 퍼즐 버튼
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
                            MouseRegion(
                              onEnter: (_) =>
                                  setState(() => _puzzleHovered = true),
                              onExit: (_) =>
                                  setState(() => _puzzleHovered = false),
                              child: GestureDetector(
                                onTap: () {},
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: _puzzleHovered
                                        ? AppTheme.primary
                                        : const Color(0xFFF0F4F8),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: _puzzleHovered
                                          ? AppTheme.primary
                                          : const Color(0xFFDDE4EE),
                                    ),
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
                                    _puzzleHovered
                                        ? Icons.extension
                                        : Icons.extension_outlined,
                                    size: 22,
                                    color: _puzzleHovered
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
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
