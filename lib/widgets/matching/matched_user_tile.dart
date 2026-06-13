import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../constants/profile_labels.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';
import '../../utils/avatar_color.dart';
import '../home/match_card.dart';

class MatchedUserTile extends StatelessWidget {
  final MatchUser user;
  final VoidCallback onToggle;
  final VoidCallback onStartChat;
  final bool isInChat;

  const MatchedUserTile({
    super.key,
    required this.user,
    required this.onToggle,
    required this.onStartChat,
    this.isInChat = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = avatarColorFor(user.name);
    return GestureDetector(
      onTap: () => _showDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // 아바타 (이름 기반 색상 + 첫 글자)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  avatarInitial(user.name),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 이름 · 국기 / 학과 · 학년 / 언어 태그
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (user.countryFlag.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Text(
                          user.countryFlag,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      // 채팅 중 표시
                      if (isInChat) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.mint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppTheme.mint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                '채팅 중',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.mint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${user.major} · ${user.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (user.languages.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: user.languages.take(3).map((lang) {
                        final label = languageLabelOf(
                            context.locale.languageCode)(lang);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.18)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.translate_rounded,
                                  size: 9, color: AppTheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // 매칭도 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${user.matchPercent}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.68,
              child: MatchCard(
                user: user,
                isMatched: true,
                isInChat: isInChat,
                onMatchTap: () {
                  onToggle();
                  Navigator.pop(context);
                },
                onChatTap: () {
                  Navigator.pop(context);
                  onStartChat();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
