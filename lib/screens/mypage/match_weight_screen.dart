import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/match_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/helping/picker_sheets.dart';

// ── 중요도 레벨 ───────────────────────────────────────────────────────────────

enum _Level { low, medium, high, veryHigh }

const Map<_Level, int> _levelRaw = {
  _Level.low: 5,
  _Level.medium: 15,
  _Level.high: 25,
  _Level.veryHigh: 35,
};

const Map<_Level, String> _levelKey = {
  _Level.low: 'weight.level_low',
  _Level.medium: 'weight.level_medium',
  _Level.high: 'weight.level_high',
  _Level.veryHigh: 'weight.level_very_high',
};

// ── 항목 정의 ─────────────────────────────────────────────────────────────────

class _WeightDef {
  final String key;
  final String labelKey;
  final String descKey;
  final Color color;
  final IconData icon;

  const _WeightDef({
    required this.key,
    required this.labelKey,
    required this.descKey,
    required this.color,
    required this.icon,
  });
}

const _kDefs = [
  _WeightDef(
    key: 'purpose',
    labelKey: 'weight.purpose',
    descKey: 'weight.purpose_desc',
    color: Color(0xFF4C80AF),
    icon: Icons.swap_horiz_rounded,
  ),
  _WeightDef(
    key: 'interests',
    labelKey: 'weight.interests',
    descKey: 'weight.interests_desc',
    color: Color(0xFF3ABBA0),
    icon: Icons.favorite_border_rounded,
  ),
  _WeightDef(
    key: 'language',
    labelKey: 'weight.language',
    descKey: 'weight.language_desc',
    color: Color(0xFF8B5CF6),
    icon: Icons.translate_rounded,
  ),
  _WeightDef(
    key: 'personality',
    labelKey: 'weight.personality',
    descKey: 'weight.personality_desc',
    color: Color(0xFFF59E0B),
    icon: Icons.psychology_outlined,
  ),
  _WeightDef(
    key: 'major',
    labelKey: 'weight.major',
    descKey: 'weight.major_desc',
    color: Color(0xFFEF4444),
    icon: Icons.school_outlined,
  ),
  _WeightDef(
    key: 'year',
    labelKey: 'weight.year',
    descKey: 'weight.year_desc',
    color: Color(0xFF10B981),
    icon: Icons.calendar_today_outlined,
  ),
  _WeightDef(
    key: 'nationality',
    labelKey: 'weight.nationality',
    descKey: 'weight.nationality_desc',
    color: Color(0xFFEC4899),
    icon: Icons.public_rounded,
  ),
];

// ── 화면 ──────────────────────────────────────────────────────────────────────

class MatchWeightScreen extends StatefulWidget {
  final UserModel user;

  const MatchWeightScreen({super.key, required this.user});

  @override
  State<MatchWeightScreen> createState() => _MatchWeightScreenState();
}

class _MatchWeightScreenState extends State<MatchWeightScreen> {
  late final List<_Level> _levels;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _levels = [
      _rawToLevel(widget.user.weightPurpose),
      _rawToLevel(widget.user.weightInterests),
      _rawToLevel(widget.user.weightLanguage),
      _rawToLevel(widget.user.weightPersonality),
      _rawToLevel(widget.user.weightMajor),
      _rawToLevel(widget.user.weightYear),
      _rawToLevel(widget.user.weightNationality),
    ];
  }

  /// 저장된 가중치 값을 가장 가까운 레벨로 변환
  _Level _rawToLevel(int weight) {
    if (weight <= 8) return _Level.low;
    if (weight <= 18) return _Level.medium;
    if (weight <= 28) return _Level.high;
    return _Level.veryHigh;
  }

  /// 현재 레벨 선택을 합계 100인 가중치로 변환
  Map<String, int> _computeWeights() {
    final rawTotal =
        _levels.fold(0, (s, l) => s + _levelRaw[l]!);
    final result = <String, int>{};
    int assigned = 0;
    for (int i = 0; i < _kDefs.length - 1; i++) {
      final w = (_levelRaw[_levels[i]]! / rawTotal * 100).round();
      result[_kDefs[i].key] = w;
      assigned += w;
    }
    result[_kDefs.last.key] = 100 - assigned;
    return result;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final w = _computeWeights();

    try {
      await MatchService.saveWeights(
        widget.user.email,
        weightPurpose: w['purpose']!,
        weightInterests: w['interests']!,
        weightLanguage: w['language']!,
        weightPersonality: w['personality']!,
        weightMajor: w['major']!,
        weightYear: w['year']!,
        weightNationality: w['nationality']!,
      );

      final updated = widget.user.copyWith(
        weightPurpose: w['purpose']!,
        weightInterests: w['interests']!,
        weightLanguage: w['language']!,
        weightPersonality: w['personality']!,
        weightMajor: w['major']!,
        weightYear: w['year']!,
        weightNationality: w['nationality']!,
      );
      await UserService.saveUser(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('weight.save_success'.tr()),
          backgroundColor: AppTheme.mint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('weight.save_error'.tr()),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'weight.title'.tr(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 설명
                  _DescCard(),
                  const SizedBox(height: 20),

                  // 항목 카드
                  for (int i = 0; i < _kDefs.length; i++) ...[
                    _WeightItemCard(
                      def: _kDefs[i],
                      level: _levels[i],
                      onChanged: (l) =>
                          setState(() => _levels[i] = l),
                    ),
                    if (i < _kDefs.length - 1)
                      const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 저장 버튼
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: hoverPrimaryButtonStyle(),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'weight.save'.tr(),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 상단 설명 카드 ─────────────────────────────────────────────────────────────

class _DescCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'weight.desc_title'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'weight.desc_body'.tr(),
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 항목 카드 ─────────────────────────────────────────────────────────────────

class _WeightItemCard extends StatelessWidget {
  final _WeightDef def;
  final _Level level;
  final ValueChanged<_Level> onChanged;

  const _WeightItemCard({
    required this.def,
    required this.level,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘 + 항목명 + 현재 레벨
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: def.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(def.icon, size: 18, color: def.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.labelKey.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      def.descKey.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 현재 선택된 레벨 뱃지
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Container(
                  key: ValueKey(level),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: def.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _levelKey[level]!.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: def.color,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 세그먼트 바
          _SegmentBar(
            level: level,
            color: def.color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── 세그먼트 바 ───────────────────────────────────────────────────────────────

class _SegmentBar extends StatelessWidget {
  final _Level level;
  final Color color;
  final ValueChanged<_Level> onChanged;

  const _SegmentBar({
    required this.level,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final levels = _Level.values;

    return Column(
      children: [
        // 세그먼트 바 본체
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: levels.asMap().entries.map((entry) {
              final idx = entry.key;
              final lvl = entry.value;
              final isFilled = lvl.index <= level.index;
              final isFirst = idx == 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(lvl),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 28,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? color.withValues(
                              alpha: 0.25 + lvl.index * 0.2)
                          : color.withValues(alpha: 0.07),
                      border: isFirst
                          ? null
                          : Border(
                              left: BorderSide(
                                  color: Colors.white, width: 3)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 7),

        // 레벨 레이블
        Row(
          children: levels.map((lvl) {
            final isSelected = lvl == level;
            return Expanded(
              child: Text(
                _levelKey[lvl]!.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.normal,
                  color:
                      isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
