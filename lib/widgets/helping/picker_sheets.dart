import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ── 날짜 선택 바텀시트 ────────────────────────────────────────────────────────

class DatePickerSheet extends StatefulWidget {
  final DateTime initialDate;

  const DatePickerSheet({super.key, required this.initialDate});

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildTitle('날짜 선택'),
          SizedBox(
            height: 220,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selected,
              minimumDate: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day),
              maximumDate: DateTime.now().add(const Duration(days: 365)),
              onDateTimeChanged: (dt) => setState(() => _selected = dt),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              style: hoverPrimaryButtonStyle(),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 시간 선택 바텀시트 ────────────────────────────────────────────────────────

class TimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;

  const TimePickerSheet({super.key, required this.initialDateTime});

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    // 분을 15분 단위로 반올림해서 초기값 설정
    final m = (widget.initialDateTime.minute / 15).round() * 15;
    _selected = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
      widget.initialDateTime.hour,
      m % 60,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildTitle('시간 선택'),
          SizedBox(
            height: 220,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: _selected,
              use24hFormat: false,
              minuteInterval: 5,
              onDateTimeChanged: (dt) => setState(() => _selected = dt),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              style: hoverPrimaryButtonStyle(),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공통 헬퍼 ─────────────────────────────────────────────────────────────────

ButtonStyle hoverPrimaryButtonStyle() {
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) return AppTheme.primary;
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) return Colors.white;
      return AppTheme.primary;
    }),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(0),
    side: const WidgetStatePropertyAll(BorderSide(color: AppTheme.primary)),
    shape: const WidgetStatePropertyAll(RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    )),
    minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 48)),
    textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    animationDuration: const Duration(milliseconds: 150),
  );
}

Widget _buildHandle() {
  return Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _buildTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    ),
  );
}
