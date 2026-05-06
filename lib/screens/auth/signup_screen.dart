import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../constants/knu_data.dart';
import '../../widgets/auth/dropdown_field.dart';
import 'email_verify_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailPrefixController = TextEditingController();

  String? _selectedCollege;    // 단과대
  String? _selectedDept;       // 학부
  String? _selectedCountry;    // 국가
  bool _isLoading = false;

  List<String> get _deptList =>
      _selectedCollege != null ? knuDepartments[_selectedCollege!] ?? [] : [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailPrefixController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollege == null) {
      _showSnackBar('단과대를 선택해주세요');
      return;
    }
    if (_selectedDept == null) {
      _showSnackBar('학부/학과를 선택해주세요');
      return;
    }
    if (_selectedCountry == null) {
      _showSnackBar('국가를 선택해주세요');
      return;
    }

    setState(() => _isLoading = true);

    // TODO: 백엔드 API 연동
    // final response = await AuthService.signup(
    //   name: _nameController.text,
    //   email: '${_emailPrefixController.text}@kangwon.ac.kr',
    //   college: _selectedCollege!,
    //   department: _selectedDept!,
    //   country: _selectedCountry!,
    // );

    await Future.delayed(const Duration(seconds: 1)); // 임시

    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailVerifyScreen(
          email: '${_emailPrefixController.text}@kangwon.ac.kr',
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
          '회원가입',
          style: TextStyle(
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
              // 이름
              _label('이름'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: '이름을 입력해주세요'),
                validator: (v) =>
                    v == null || v.isEmpty ? '이름을 입력해주세요' : null,
              ),
              const SizedBox(height: 20),

              // 단과대
              _label('단과대'),
              SelectorButton(
                hint: '단과대를 선택해주세요',
                value: _selectedCollege,
                onTap: () async {
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SimplePickerSheet(
                      title: '단과대',
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

              // 학부
              _label('학부/학과'),
              SelectorButton(
                hint: _selectedCollege == null
                    ? '단과대를 먼저 선택해주세요'
                    : '학부/학과를 선택해주세요',
                value: _selectedDept,
                onTap: _selectedCollege == null
                    ? null
                    : () async {
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => SimplePickerSheet(
                            title: '학부/학과',
                            items: _deptList,
                            selectedItem: _selectedDept,
                          ),
                        );
                        if (result != null) setState(() => _selectedDept = result);
                      },
              ),
              const SizedBox(height: 20),

              // 국가
              _label('국가'),
              _buildCountrySelector(),
              const SizedBox(height: 20),

              // 학교 이메일
              _label('학교 이메일'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailPrefixController,
                      validator: (v) =>
                          v == null || v.isEmpty ? '이메일을 입력해주세요' : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '@kangwon.ac.kr',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 인증하기 버튼
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('인증하기'),
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

  Widget _buildCountrySelector() {
    return SelectorButton(
      hint: '국가를 선택해주세요',
      value: _selectedCountry,
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CountryPickerSheet(selectedCountry: _selectedCountry),
        );
        if (result != null) setState(() => _selectedCountry = result);
      },
    );
  }
}
