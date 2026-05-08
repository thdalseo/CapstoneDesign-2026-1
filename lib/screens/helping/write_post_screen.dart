import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/dropdown_field.dart';
import '../../widgets/helping/picker_sheets.dart';

class WritePostScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const WritePostScreen({super.key, this.initialData});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _memoController = TextEditingController();

  UserModel? _currentUser;
  String _selectedCategory = '수업';
  bool _isUrgent = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  static const List<String> _categories = ['생활', '수업', '언어', '의료', '캠퍼스', '행정'];

  bool get _isEditing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    UserService.loadUser().then((u) {
      if (mounted) setState(() => _currentUser = u);
    });
    if (_isEditing) {
      final d = widget.initialData!;
      _titleController.text = d['title'] as String? ?? '';
      _placeController.text = d['place'] as String? ?? '';
      _memoController.text = d['memo'] as String? ?? '';
      final cat = d['category'] as String? ?? '수업';
      _selectedCategory = _categories.contains(cat) ? cat : '수업';
      _isUrgent = d['isUrgent'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DatePickerSheet(initialDate: initial),
    );
    if (result != null) setState(() => _selectedDate = result);
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final initial = _selectedTime != null
        ? DateTime(now.year, now.month, now.day,
            _selectedTime!.hour, _selectedTime!.minute)
        : now;
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimePickerSheet(initialDateTime: initial),
    );
    if (result != null) {
      setState(() => _selectedTime = TimeOfDay.fromDateTime(result));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '날짜를 선택해주세요';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '시간을 선택해주세요';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    return '$period $hour:$minute';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('날짜를 선택해주세요')));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('시간을 선택해주세요')));
      return;
    }

    // TODO: 백엔드 API 연동
    // POST /api/help-posts      → 글 작성
    // PUT  /api/help-posts/{id} → 글 수정

    final result = {
      'id': widget.initialData?['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'category': _selectedCategory,
      'isUrgent': _isUrgent,
      'title': _titleController.text.trim(),
      'place': _placeController.text.trim(),
      'date': _formatDate(_selectedDate),
      'time': _formatTime(_selectedTime),
      'memo': _memoController.text.trim(),
      'authorName': widget.initialData?['authorName'] ?? (_currentUser?.name ?? ''),
      'major': widget.initialData?['major'] ?? (_currentUser?.major ?? ''),
      'timeAgo': '방금 전',
      'helperCount': widget.initialData?['helperCount'] ?? 0,
      'isCompleted': widget.initialData?['isCompleted'] ?? false,
      'isMyPost': true,
    };
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? '게시글 수정' : '도움 요청하기',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            _label('카테고리'),
            const SizedBox(height: 8),
            SelectorButton(
              hint: '카테고리를 선택해주세요',
              value: _selectedCategory,
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SimplePickerSheet(
                    title: '카테고리',
                    items: _categories,
                    selectedItem: _selectedCategory,
                  ),
                );
                if (result != null) setState(() => _selectedCategory = result);
              },
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '긴급',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Switch(
                  value: _isUrgent,
                  onChanged: (v) => setState(() => _isUrgent = v),
                  activeThumbColor: const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _label('제목'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: '제목을 입력해주세요'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 20),

            _label('장소'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _placeController,
              decoration: const InputDecoration(hintText: '장소를 입력해주세요'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '장소를 입력해주세요' : null,
            ),
            const SizedBox(height: 20),

            _label('날짜'),
            const SizedBox(height: 8),
            _pickerButton(
              icon: Icons.calendar_today_outlined,
              text: _formatDate(_selectedDate),
              isEmpty: _selectedDate == null,
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),

            _label('시간'),
            const SizedBox(height: 8),
            _pickerButton(
              icon: Icons.access_time_outlined,
              text: _formatTime(_selectedTime),
              isEmpty: _selectedTime == null,
              onTap: _pickTime,
            ),
            const SizedBox(height: 20),

            _label('메모'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '도움 요청 내용을 자세히 작성해주세요',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _submit,
              style: hoverPrimaryButtonStyle(),
              child: Text(_isEditing ? '수정하기' : '등록하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String text,
    required bool isEmpty,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isEmpty ? const Color(0xFFBBBBBB) : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
