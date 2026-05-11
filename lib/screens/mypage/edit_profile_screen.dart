import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../constants/profile_data.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/mypage/profile_image_picker.dart';
import '../../widgets/mypage/grid_chips.dart';
import '../../widgets/mypage/custom_chip_input.dart';
import '../../widgets/mypage/hover_button.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? user;
  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _introController = TextEditingController();
  final _customInterestController = TextEditingController();
  final _customPersonalityController = TextEditingController();
  final _customLanguageController = TextEditingController();

  String _pickedImagePath = '';
  String _selectedYear = '';
  List<String> _selectedInterests = [];
  List<String> _selectedPersonalities = [];
  List<String> _selectedLanguages = [];
  List<String> _selectedPurposes = [];

  final List<String> _customInterests = [];
  final List<String> _customPersonalities = [];
  final List<String> _customLanguages = [];

  static const _yearOptions = ['1학년', '2학년', '3학년', '4학년'];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    if (u != null) {
      _introController.text = u.description;
      _selectedYear = u.year;
      _selectedInterests = List.of(u.interests);
      _selectedPurposes = List.of(u.exchangePurposes);
      _selectedPersonalities = List.of(u.personalities);
      _selectedLanguages = List.of(u.languages);
      if (u.avatarUrl != null && !u.avatarUrl!.startsWith('http')) {
        _pickedImagePath = u.avatarUrl!;
      }
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _customInterestController.dispose();
    _customPersonalityController.dispose();
    _customLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '프로필 편집',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '저장',
              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileImagePicker(
              onTap: _pickImage,
              imagePath: _pickedImagePath.isNotEmpty ? _pickedImagePath : null,
            ),
            const SizedBox(height: 28),

            _sectionTitle('학년'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedYear.isEmpty ? null : _selectedYear,
              hint: const Text('학년 선택', style: TextStyle(fontSize: 13, color: Color(0xFFAAB4C0))),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
              items: _yearOptions
                  .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedYear = v ?? ''),
            ),
            const SizedBox(height: 24),

            _sectionTitle('자기소개'),
            const SizedBox(height: 10),
            TextField(
              controller: _introController,
              maxLines: 4,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: '자신을 소개하는 글을 작성해 주세요.',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAB4C0)),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('교류 목적', hint: '중복 선택 가능'),
            const SizedBox(height: 10),
            GridChips(
              items: exchangePurposeList,
              selected: _selectedPurposes,
              onTap: (item) => _toggle(_selectedPurposes, item),
            ),
            const SizedBox(height: 24),

            _sectionTitle('관심사', hint: '기타 항목 포함 최대 3개 선택 가능'),
            const SizedBox(height: 10),
            GridChips(
              items: interestList,
              selected: _selectedInterests,
              onTap: (item) => _toggle(_selectedInterests, item, maxCount: 3, extraList: _customInterests),
            ),
            const SizedBox(height: 8),
            CustomChipInput(
              controller: _customInterestController,
              customItems: _customInterests,
              hintText: '기타',
              onAdd: () => _addCustom(_customInterestController, _customInterests, baseList: _selectedInterests, maxCount: 3),
              onRemove: (item) => setState(() => _customInterests.remove(item)),
            ),
            const SizedBox(height: 24),

            _sectionTitle('성향', hint: '기타 항목 포함 최대 3개 선택 가능'),
            const SizedBox(height: 10),
            GridChips(
              items: personalityList,
              selected: _selectedPersonalities,
              onTap: (item) => _toggle(_selectedPersonalities, item, maxCount: 3, extraList: _customPersonalities),
            ),
            const SizedBox(height: 8),
            CustomChipInput(
              controller: _customPersonalityController,
              customItems: _customPersonalities,
              hintText: '기타',
              onAdd: () => _addCustom(_customPersonalityController, _customPersonalities, baseList: _selectedPersonalities, maxCount: 3),
              onRemove: (item) => setState(() => _customPersonalities.remove(item)),
            ),
            const SizedBox(height: 24),

            _sectionTitle('사용 가능 언어'),
            const SizedBox(height: 10),
            GridChips(
              items: languageList,
              selected: _selectedLanguages,
              onTap: (item) => _toggle(_selectedLanguages, item),
            ),
            const SizedBox(height: 8),
            CustomChipInput(
              controller: _customLanguageController,
              customItems: _customLanguages,
              hintText: '기타',
              onAdd: () => _addCustom(_customLanguageController, _customLanguages),
              onRemove: (item) => setState(() => _customLanguages.remove(item)),
            ),
            const SizedBox(height: 40),

            HoverButton(
              label: '저장하기',
              onPressed: _save,
              color: AppTheme.primary,
              width: double.infinity,
              height: 52,
              fontSize: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAB4C0)),
          ),
        ],
      ],
    );
  }

  void _toggle(List<String> list, String item, {int? maxCount, List<String>? extraList}) {
    setState(() {
      if (list.contains(item)) {
        list.remove(item);
      } else {
        final total = list.length + (extraList?.length ?? 0);
        if (maxCount == null || total < maxCount) {
          list.add(item);
        }
      }
    });
  }

  void _addCustom(
    TextEditingController controller,
    List<String> list, {
    List<String>? baseList,
    int? maxCount,
  }) {
    final text = controller.text.trim();
    if (text.isEmpty || list.contains(text)) return;
    final total = list.length + (baseList?.length ?? 0);
    if (maxCount != null && total >= maxCount) return;
    setState(() {
      list.add(text);
      controller.clear();
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _pickedImagePath = picked.path);
  }

  Future<void> _save() async {
    final currentUser = await UserService.loadUser();
    if (currentUser == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final updated = currentUser.copyWith(
      year: _selectedYear,
      interests: [..._selectedInterests, ..._customInterests],
      exchangePurposes: _selectedPurposes,
      personalities: [..._selectedPersonalities, ..._customPersonalities],
      languages: [..._selectedLanguages, ..._customLanguages],
      description: _introController.text.trim(),
      avatarUrl: _pickedImagePath.isNotEmpty ? _pickedImagePath : currentUser.avatarUrl,
    );
    await UserService.saveUser(updated);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('프로필이 저장됐어요!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
