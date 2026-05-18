import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/user_model.dart';
import '../../services/help_post_service.dart';
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
  bool _isSubmitting = false;

  // DB 저장값(한국어) 그대로 유지
  static const List<String> _categoryValues = [
    '생활', '수업', '언어', '의료', '캠퍼스', '행정',
  ];

  static const Map<String, String> _categoryKeys = {
    '생활': 'help.cat_living',
    '수업': 'help.cat_class',
    '언어': 'help.cat_language',
    '의료': 'help.cat_medical',
    '캠퍼스': 'help.cat_campus',
    '행정': 'help.cat_admin',
  };

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
      _selectedCategory = _categoryValues.contains(cat) ? cat : '수업';
      _isUrgent = d['isUrgent'] as bool? ?? false;

      final rawDate = d['rawDate'] as String? ?? '';
      if (rawDate.isNotEmpty) {
        final parts = rawDate.split('-');
        if (parts.length == 3) {
          _selectedDate = DateTime(
            int.tryParse(parts[0]) ?? DateTime.now().year,
            int.tryParse(parts[1]) ?? 1,
            int.tryParse(parts[2]) ?? 1,
          );
        }
      }

      final rawTime = d['rawTime'] as String? ?? '';
      if (rawTime.isNotEmpty) {
        final parts = rawTime.split(':');
        if (parts.length >= 2) {
          _selectedTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
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
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DatePickerSheet(initialDate: _selectedDate ?? now),
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

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return 'write_post.date_hint'.tr();
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatTimeDisplay(TimeOfDay? time) {
    if (time == null) return 'write_post.time_hint'.tr();
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    return '$period $hour:$minute';
  }

  String _toApiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _toApiTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('write_post.date_hint'.tr())));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('write_post.time_hint'.tr())));
      return;
    }
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.login_required'.tr())));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isEditing) {
        final postId = widget.initialData!['id'] as int;
        await HelpPostService.updatePost(
          postId,
          category: _selectedCategory,
          title: _titleController.text.trim(),
          place: _placeController.text.trim(),
          date: _toApiDate(_selectedDate!),
          time: _toApiTime(_selectedTime!),
          memo: _memoController.text.trim(),
          isUrgent: _isUrgent,
        );
      } else {
        await HelpPostService.createPost(
          authorEmail: _currentUser!.email,
          category: _selectedCategory,
          title: _titleController.text.trim(),
          place: _placeController.text.trim(),
          date: _toApiDate(_selectedDate!),
          time: _toApiTime(_selectedTime!),
          memo: _memoController.text.trim(),
          isUrgent: _isUrgent,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('common.network_error'.tr()),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          _isEditing
              ? 'write_post.title_edit'.tr()
              : 'write_post.title_create'.tr(),
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
            _label('write_post.category'.tr()),
            const SizedBox(height: 8),
            SelectorButton(
              hint: 'write_post.category_hint'.tr(),
              value: (_categoryKeys[_selectedCategory] ?? _selectedCategory).tr(),
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SimplePickerSheet(
                    title: 'write_post.category'.tr(),
                    items: _categoryValues,
                    selectedItem: _selectedCategory,
                    itemLabel: (v) =>
                        (_categoryKeys[v] ?? v).tr(),
                  ),
                );
                if (result != null) setState(() => _selectedCategory = result);
              },
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'write_post.urgent'.tr(),
                  style: const TextStyle(
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

            _label('write_post.title_field'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                  hintText: 'write_post.title_hint'.tr()),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'write_post.title_required'.tr()
                  : null,
            ),
            const SizedBox(height: 20),

            _label('write_post.place'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _placeController,
              decoration: InputDecoration(
                  hintText: 'write_post.place_hint'.tr()),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'write_post.place_required'.tr()
                  : null,
            ),
            const SizedBox(height: 20),

            _label('write_post.date'.tr()),
            const SizedBox(height: 8),
            _pickerButton(
              icon: Icons.calendar_today_outlined,
              text: _formatDateDisplay(_selectedDate),
              isEmpty: _selectedDate == null,
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),

            _label('write_post.time'.tr()),
            const SizedBox(height: 8),
            _pickerButton(
              icon: Icons.access_time_outlined,
              text: _formatTimeDisplay(_selectedTime),
              isEmpty: _selectedTime == null,
              onTap: _pickTime,
            ),
            const SizedBox(height: 20),

            _label('write_post.memo'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'write_post.memo_hint'.tr(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: hoverPrimaryButtonStyle(),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing
                      ? 'write_post.update'.tr()
                      : 'write_post.submit'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      );

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
                color: isEmpty
                    ? const Color(0xFFBBBBBB)
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
