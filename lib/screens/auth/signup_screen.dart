import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../constants/knu_data.dart';
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
              _buildDropdown(
                hint: '단과대를 선택해주세요',
                value: _selectedCollege,
                items: knuDepartments.keys.toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCollege = val;
                    _selectedDept = null; // 학부 초기화
                  });
                },
              ),
              const SizedBox(height: 20),

              // 학부
              _label('학부/학과'),
              _buildDropdown(
                hint: _selectedCollege == null
                    ? '단과대를 먼저 선택해주세요'
                    : '학부/학과를 선택해주세요',
                value: _selectedDept,
                items: _deptList,
                onChanged: _selectedCollege == null
                    ? null
                    : (val) => setState(() => _selectedDept = val),
              ),
              const SizedBox(height: 20),

              // 국가
              _label('국가'),
              _buildDropdown(
                hint: '국가를 선택해주세요',
                value: _selectedCountry,
                items: countries,
                onChanged: (val) => setState(() => _selectedCountry = val),
              ),
              const SizedBox(height: 20),

              // 학교 이메일
              _label('학교 이메일'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailPrefixController,
                      decoration: const InputDecoration(
                        hintText: '학번 입력',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? '학번을 입력해주세요' : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDE4EE)),
                    ),
                    child: const Text(
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

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE4EE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFBBBBBB),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}