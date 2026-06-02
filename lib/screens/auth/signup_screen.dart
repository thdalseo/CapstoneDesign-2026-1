import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../constants/knu_data.dart';
import '../../widgets/auth/dropdown_field.dart';
import 'email_verify_screen.dart';

// 지원 언어 목록
const _kLangs = [
  {'code': 'ko', 'flag': '🇰🇷', 'label': '한국어'},
  {'code': 'en', 'flag': '🇺🇸', 'label': 'English'},
  {'code': 'ja', 'flag': '🇯🇵', 'label': '日本語'},
  {'code': 'zh', 'flag': '🇨🇳', 'label': '中文'},
  {'code': 'vi', 'flag': '🇻🇳', 'label': 'Tiếng Việt'},
];

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailPrefixController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _selectedCollege;
  String? _selectedDept;
  String? _selectedCountry;
  bool _isLoading = false;

  List<String> get _deptList =>
      _selectedCollege != null ? knuDepartments[_selectedCollege!] ?? [] : [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailPrefixController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollege == null) { _showSnackBar('auth.college_required'.tr()); return; }
    if (_selectedDept == null)    { _showSnackBar('auth.dept_required'.tr()); return; }
    if (_selectedCountry == null) { _showSnackBar('auth.country_required'.tr()); return; }

    setState(() => _isLoading = true);

    final email = '${_emailPrefixController.text.trim()}@kangwon.ac.kr';

    try {
      await AuthService.sendCode(email);
    } on ApiException catch (e) {
      _showSnackBar(e.message);
      setState(() => _isLoading = false);
      return;
    } catch (_) {
      _showSnackBar('common.network_error'.tr());
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailVerifyScreen(
          email: email,
          password: _passwordController.text,
          name: _nameController.text.trim(),
          country: _selectedCountry!,
          college: _selectedCollege!,
          major: _selectedDept!,
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = context.locale.languageCode;

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
          'auth.signup_title'.tr(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 언어 선택 ──────────────────────────────────────────────────
              _label('auth.language'.tr()),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (_kLangs.length - 1)) /
                          _kLangs.length;
                  return Row(
                    children: [
                      for (int i = 0; i < _kLangs.length; i++) ...[
                        if (i > 0) const SizedBox(width: spacing),
                        GestureDetector(
                          onTap: () =>
                              context.setLocale(Locale(_kLangs[i]['code']!)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: itemWidth,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _kLangs[i]['code'] == currentLang
                                  ? AppTheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _kLangs[i]['code'] == currentLang
                                    ? AppTheme.primary
                                    : const Color(0xFFDDE4EE),
                                width: _kLangs[i]['code'] == currentLang
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            child: Text(
                              '${_kLangs[i]['flag']} ${_kLangs[i]['label']}',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: _kLangs[i]['code'] == currentLang
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontWeight: _kLangs[i]['code'] == currentLang
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── 이름 ──────────────────────────────────────────────────────
              _label('auth.name'.tr()),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(hintText: 'auth.name_hint'.tr()),
                validator: (v) =>
                    v == null || v.isEmpty ? 'auth.name_required'.tr() : null,
              ),
              const SizedBox(height: 20),

              // ── 단과대 ────────────────────────────────────────────────────
              _label('auth.college'.tr()),
              SelectorButton(
                hint: 'auth.college_hint'.tr(),
                value: _selectedCollege,
                onTap: () async {
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SimplePickerSheet(
                      title: 'auth.college'.tr(),
                      items: knuDepartments.keys.toList(),
                      selectedItem: _selectedCollege,
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedCollege = result;
                      _selectedDept = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // ── 학부/학과 ─────────────────────────────────────────────────
              _label('auth.dept'.tr()),
              SelectorButton(
                hint: _selectedCollege == null
                    ? 'auth.dept_hint_first'.tr()
                    : 'auth.dept_hint'.tr(),
                value: _selectedDept,
                onTap: _selectedCollege == null
                    ? null
                    : () async {
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => SimplePickerSheet(
                            title: 'auth.dept'.tr(),
                            items: _deptList,
                            selectedItem: _selectedDept,
                          ),
                        );
                        if (result != null) setState(() => _selectedDept = result);
                      },
              ),
              const SizedBox(height: 20),

              // ── 국가 ──────────────────────────────────────────────────────
              _label('auth.country'.tr()),
              SelectorButton(
                hint: 'auth.country_hint'.tr(),
                value: _selectedCountry,
                onTap: () async {
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        CountryPickerSheet(selectedCountry: _selectedCountry),
                  );
                  if (result != null) setState(() => _selectedCountry = result);
                },
              ),
              const SizedBox(height: 20),

              // ── 학교 이메일 ───────────────────────────────────────────────
              _label('auth.email'.tr()),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailPrefixController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(hintText: 'auth.email_hint'.tr()),
                      validator: (v) => v == null || v.isEmpty
                          ? 'auth.email_required'.tr()
                          : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '@kangwon.ac.kr',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 비밀번호 ──────────────────────────────────────────────────
              _label('auth.password'.tr()),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  hintText: 'auth.password_hint'.tr(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'auth.password_required'.tr();
                  if (v.length < 8) return 'auth.password_min'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── 비밀번호 확인 ─────────────────────────────────────────────
              _label('auth.password_confirm'.tr()),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'auth.password_confirm_hint'.tr(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => setState(
                        () => _confirmPasswordVisible = !_confirmPasswordVisible),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'auth.password_confirm_required'.tr();
                  if (v != _passwordController.text)
                    return 'auth.password_mismatch'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // ── 인증하기 버튼 ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('auth.submit'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
