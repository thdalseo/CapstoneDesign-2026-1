import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../constants/profile_data.dart';
import '../../constants/profile_labels.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/auth/dropdown_field.dart';
import '../../widgets/mypage/profile_image_picker.dart';
import '../../widgets/mypage/grid_chips.dart';
import '../../widgets/mypage/custom_chip_input.dart';
import '../../widgets/mypage/hover_button.dart';
import 'match_weight_screen.dart';

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

  static const _yearOptions = [
    '1학년', '2학년', '3학년', '4학년', '5학년', '6학년'
  ];

  // 학년 → 번역 키
  String _trYear(String year) {
    final n = year.replaceAll('학년', '');
    return 'edit_profile.year_$n'.tr();
  }

  // ── 로케일별 라벨 헬퍼 (profile_labels.dart 위임) ───────────────────────────
  String get _locale => context.locale.languageCode;

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
        title: Text(
          'edit_profile.title'.tr(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'edit_profile.save'.tr(),
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w600),
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
              imagePath:
                  _pickedImagePath.isNotEmpty ? _pickedImagePath : null,
            ),
            const SizedBox(height: 28),

            // 학년
            _sectionTitle('edit_profile.year'.tr()),
            const SizedBox(height: 10),
            SelectorButton(
              hint: 'edit_profile.year_hint'.tr(),
              value: _selectedYear.isEmpty ? null : _trYear(_selectedYear),
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => SimplePickerSheet(
                    title: 'edit_profile.year'.tr(),
                    items: _yearOptions,
                    selectedItem:
                        _selectedYear.isEmpty ? null : _selectedYear,
                    itemLabel: _trYear,
                  ),
                );
                if (result != null) setState(() => _selectedYear = result);
              },
            ),
            const SizedBox(height: 24),

            // 자기소개
            _sectionTitle('edit_profile.intro'.tr()),
            const SizedBox(height: 10),
            TextField(
              controller: _introController,
              maxLines: 4,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'edit_profile.intro_hint'.tr(),
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFFAAB4C0)),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFDDE4EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFDDE4EE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 교류 목적
            _sectionTitle('edit_profile.purpose'.tr(),
                hint: 'edit_profile.purpose_hint'.tr()),
            const SizedBox(height: 10),
            GridChips(
              items: exchangePurposeList,
              selected: _selectedPurposes,
              onTap: (item) => _toggle(_selectedPurposes, item),
              labelOf: purposeLabelOf(_locale),
            ),
            const SizedBox(height: 24),

            // 관심사
            _sectionTitle('edit_profile.interests'.tr(),
                hint: 'edit_profile.multi_hint'.tr()),
            const SizedBox(height: 10),
            GridChips(
              items: interestList,
              selected: _selectedInterests,
              onTap: (item) => _toggle(_selectedInterests, item,
                  maxCount: 3, extraList: _customInterests),
              labelOf: interestLabelOf(_locale),
            ),
            const SizedBox(height: 8),
            CustomChipInput(
              controller: _customInterestController,
              customItems: _customInterests,
              hintText: 'edit_profile.other'.tr(),
              onAdd: () => _addCustom(_customInterestController,
                  _customInterests,
                  baseList: _selectedInterests, maxCount: 3),
              onRemove: (item) =>
                  setState(() => _customInterests.remove(item)),
            ),
            const SizedBox(height: 24),

            // 성향
            _sectionTitle('edit_profile.personality'.tr(),
                hint: 'edit_profile.multi_hint'.tr()),
            const SizedBox(height: 10),
            GridChips(
              items: personalityList,
              selected: _selectedPersonalities,
              onTap: (item) => _toggle(_selectedPersonalities, item,
                  maxCount: 3, extraList: _customPersonalities),
              labelOf: personalityLabelOf(_locale),
            ),
            const SizedBox(height: 8),
            CustomChipInput(
              controller: _customPersonalityController,
              customItems: _customPersonalities,
              hintText: 'edit_profile.other'.tr(),
              onAdd: () => _addCustom(_customPersonalityController,
                  _customPersonalities,
                  baseList: _selectedPersonalities, maxCount: 3),
              onRemove: (item) =>
                  setState(() => _customPersonalities.remove(item)),
            ),
            const SizedBox(height: 24),

            // 사용 가능 언어
            _sectionTitle('edit_profile.languages'.tr()),
            const SizedBox(height: 10),
            GridChips(
              items: languageList,
              selected: _selectedLanguages,
              onTap: (item) => _toggle(_selectedLanguages, item),
              labelOf: languageLabelOf(_locale),
            ),
            const SizedBox(height: 8),
            CustomChipInput(
              controller: _customLanguageController,
              customItems: _customLanguages,
              hintText: 'edit_profile.other'.tr(),
              onAdd: () =>
                  _addCustom(_customLanguageController, _customLanguages),
              onRemove: (item) =>
                  setState(() => _customLanguages.remove(item)),
            ),
            const SizedBox(height: 40),

            HoverButton(
              label: 'edit_profile.save_btn'.tr(),
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
            style:
                const TextStyle(fontSize: 12, color: Color(0xFFAAB4C0)),
          ),
        ],
      ],
    );
  }

  void _toggle(List<String> list, String item,
      {int? maxCount, List<String>? extraList}) {
    setState(() {
      if (list.contains(item)) {
        list.remove(item);
      } else {
        final total = list.length + (extraList?.length ?? 0);
        if (maxCount == null || total < maxCount) list.add(item);
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
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _pickedImagePath = picked.path);
  }

  Future<void> _save() async {
    final wasIncomplete =
        widget.user == null || !widget.user!.isProfileComplete;

    final currentUser = await UserService.loadUser();
    if (currentUser == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final updated = currentUser.copyWith(
      year: _selectedYear,
      interests: [..._selectedInterests, ..._customInterests],
      exchangePurposes: _selectedPurposes,
      personalities: [
        ..._selectedPersonalities,
        ..._customPersonalities
      ],
      languages: [..._selectedLanguages, ..._customLanguages],
      description: _introController.text.trim(),
      avatarUrl: _pickedImagePath.isNotEmpty
          ? _pickedImagePath
          : currentUser.avatarUrl,
    );
    await UserService.saveUser(updated);

    if (!mounted) return;

    // 처음으로 프로필이 완성됐을 때 → 매칭 선호도 설정 안내
    if (wasIncomplete && updated.isProfileComplete) {
      final go = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
            'edit_profile.complete_title'.tr(),
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 17),
          ),
          content: Text(
            'edit_profile.complete_desc'.tr(),
            style: const TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('common.later'.tr(),
                  style: const TextStyle(
                      color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('edit_profile.go_weight'.tr(),
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (go == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MatchWeightScreen(user: updated)),
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('edit_profile.saved'.tr()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
