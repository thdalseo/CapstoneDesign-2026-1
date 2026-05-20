import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/match_user.dart';
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

// 관심사 한→영 번역 맵
const _kInterestLabelsEn = {
  '여행': 'Travel',
  '카페 탐방': 'Cafes',
  '영화': 'Movies',
  '음악': 'Music',
  '운동': 'Exercise',
  'K-POP': 'K-POP',
  '요리': 'Cooking',
  '사진': 'Photography',
  '독서': 'Reading',
  '게임': 'Gaming',
  '드라마': 'Drama',
  '패션': 'Fashion',
  '뷰티': 'Beauty',
  '스포츠': 'Sports',
  '언어': 'Language',
};

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
          // 매칭도 뱃지 (오른쪽)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

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

class _Body extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isEn = context.locale.languageCode == 'en';
    String interestLabel(String item) =>
        isEn ? (_kInterestLabelsEn[item] ?? item) : item;

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
                user.interests.take(3).toList().asMap().entries.map((e) {
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
            child: Text(
              user.description,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textPrimary,
                height: 1.7,
              ),
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 14),

          // 버튼 영역
          if (onChatTap != null)
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
    final active = isMatched || matchHovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onMatchEnter?.call(),
      onExit: (_) => onMatchExit?.call(),
      child: GestureDetector(
        onTap: onMatchTap,
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
                isMatched ? Icons.extension : Icons.extension_outlined,
                size: 18,
                color: active ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isMatched
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
      onEnter: (_) => onChatEnter?.call(),
      onExit: (_) => onChatExit?.call(),
      child: GestureDetector(
        onTap: onChatTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            color: chatHovered ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: chatHovered ? AppTheme.primary : AppTheme.border,
            ),
            boxShadow: chatHovered
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
                chatHovered
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 17,
                color: chatHovered ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'match_card.chat'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      chatHovered ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchIconButton(BuildContext context) {
    final active = isMatched || matchHovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onMatchEnter?.call(),
      onExit: (_) => onMatchExit?.call(),
      child: GestureDetector(
        onTap: onMatchTap,
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
            isMatched ? Icons.extension : Icons.extension_outlined,
            size: 20,
            color: active ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
