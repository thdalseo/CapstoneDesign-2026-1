import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/session_history_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';


class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  Map<String, List<SessionRecord>> _byDate = {};
  bool _loading = true;

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _load();
    // 오늘을 기본 선택
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  Future<void> _load() async {
    final user = await UserService.loadUser();
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final uid = int.tryParse(user.id) ?? 0;
    final data = await SessionHistoryService.groupByDate(uid);
    if (mounted) setState(() { _byDate = data; _loading = false; });
  }

  List<SessionRecord> _recordsFor(DateTime day) {
    return _byDate[SessionHistoryService.dateKey(day)] ?? [];
  }

  int _minutesFor(DateTime day) =>
      _recordsFor(day).fold(0, (sum, r) => sum + r.minutes);

  /// 이번 달 총 분
  int get _monthTotalMinutes {
    int total = 0;
    _byDate.forEach((dateStr, records) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        if (y == _focusedMonth.year && m == _focusedMonth.month) {
          total += records.fold<int>(0, (s, r) => s + r.minutes);
        }
      }
    });
    return total;
  }

  /// 이번 달 세션 일수
  int get _monthSessionDays {
    int count = 0;
    _byDate.forEach((dateStr, records) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        if (y == _focusedMonth.year && m == _focusedMonth.month && records.isNotEmpty) {
          count++;
        }
      }
    });
    return count;
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
          'mypage.session_history'.tr(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final selectedRecords =
        _selectedDay != null ? _recordsFor(_selectedDay!) : <SessionRecord>[];

    return Column(
      children: [
        // ── 달력 카드 ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // 월 이동 헤더
              _buildMonthHeader(),
              // 요일 라벨
              _buildWeekdayRow(),
              // 날짜 그리드
              _buildCalendarGrid(),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // ── 이번 달 통계 ───────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.85),
                AppTheme.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _StatChip(
                label: 'mypage.session_days'.tr(),
                value: '$_monthSessionDays일',
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _StatChip(
                label: 'mypage.session_total_min'.tr(),
                value: '$_monthTotalMinutes분',
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── 선택된 날의 기록 ─────────────────────────────────────
        Expanded(
          child: selectedRecords.isEmpty
              ? _buildEmptyDay()
              : _buildDayRecords(selectedRecords),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    final label =
        '${_focusedMonth.year}년 ${_focusedMonth.month}월';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppTheme.textSecondary),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(
                  _focusedMonth.year, _focusedMonth.month - 1);
            }),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(
                  _focusedMonth.year, _focusedMonth.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow() {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: days
            .map(
              (d) => Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: d == '일'
                        ? Colors.red.shade300
                        : d == '토'
                            ? AppTheme.primary.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startOffset = firstDay.weekday % 7; // 0=일, 1=월 ... 6=토
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final cells = <Widget>[];

    // 앞 빈칸
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final minutes = _minutesFor(date);
      final isToday = date == todayNorm;
      final isSelected = _selectedDay != null &&
          date.year == _selectedDay!.year &&
          date.month == _selectedDay!.month &&
          date.day == _selectedDay!.day;
      final hasSession = minutes > 0;

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : isToday
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                  ),
                ),
                if (hasSession) ...[
                  const SizedBox(height: 2),
                  _MinuteDot(minutes: minutes, isSelected: isSelected),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: cells,
      ),
    );
  }

  Widget _buildEmptyDay() {
    final isSelected = _selectedDay != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                size: 26, color: AppTheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            isSelected
                ? 'mypage.session_no_record'.tr()
                : 'mypage.session_select_day'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'mypage.session_no_record_desc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRecords(List<SessionRecord> records) {
    final totalMin = records.fold<int>(0, (s, r) => s + r.minutes);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // 날짜 헤더
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                _selectedDay != null
                    ? '${_selectedDay!.month}월 ${_selectedDay!.day}일'
                    : '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '총 $totalMin분',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mint,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 기록 카드들
        ...records.map((r) => _SessionRecordCard(record: r)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// 서브 위젯들
// ────────────────────────────────────────────────────────────

/// 달력 날짜 아래 분 수 표시 점/칩
class _MinuteDot extends StatelessWidget {
  final int minutes;
  final bool isSelected;

  const _MinuteDot({required this.minutes, required this.isSelected});

  Color get _color {
    if (minutes >= 45) return AppTheme.primary;
    if (minutes >= 30) return AppTheme.primary.withValues(alpha: 0.75);
    if (minutes >= 15) return AppTheme.primary.withValues(alpha: 0.5);
    return AppTheme.mint.withValues(alpha: 0.6);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.3)
            : _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${minutes}m',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : _color,
        ),
      ),
    );
  }
}

/// 통계 칩
class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 개별 세션 기록 카드
class _SessionRecordCard extends StatelessWidget {
  final SessionRecord record;

  const _SessionRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          // 언어 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LangBadge(text: record.teach, isPrimary: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 12, color: AppTheme.textSecondary),
                    ),
                    _LangBadge(text: record.learn, isPrimary: false),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  record.partnerName.isNotEmpty
                      ? 'with ${record.partnerName}'
                      : '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 분 수
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 12, color: AppTheme.mint),
                const SizedBox(width: 3),
                Text(
                  '${record.minutes}분',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangBadge extends StatelessWidget {
  final String text;
  final bool isPrimary;

  const _LangBadge({required this.text, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? AppTheme.primary : const Color(0xFFA78BFA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
