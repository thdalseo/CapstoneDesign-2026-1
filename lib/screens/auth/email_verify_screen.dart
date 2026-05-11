import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';

class EmailVerifyScreen extends StatefulWidget {
  final String email;

  const EmailVerifyScreen({super.key, required this.email});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  static const _codeLength = 6;
  static const _timerSeconds = 300; // 5분

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  int _remainingSeconds = _timerSeconds;
  Timer? _timer;
  bool _isLoading = false;
  bool _isExpired = false;
  bool _isDistributing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _timerSeconds;
      _isExpired = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() => _isExpired = true);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String get _timerText {
    final m = _remainingSeconds ~/ 60;
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isFilled => _code.length == _codeLength;

  void _onDigitChanged(int index, String value) {
    if (_isDistributing) return;

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      // 붙여넣기: 현재 칸부터 순서대로 분배
      _isDistributing = true;
      for (int i = 0; i < digits.length && (index + i) < _codeLength; i++) {
        _controllers[index + i].text = digits[i];
      }
      _isDistributing = false;
      final nextFocus = (index + digits.length).clamp(0, _codeLength - 1);
      _focusNodes[nextFocus].requestFocus();
    } else if (digits.length == 1 && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  Future<void> _verify() async {
    if (!_isFilled || _isExpired) return;

    setState(() => _isLoading = true);

    // TODO: 백엔드 API 연동
    // final res = await http.post(
    //   Uri.parse('$baseUrl/auth/verify-code'),
    //   body: jsonEncode({'email': widget.email, 'code': _code}),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // if (res.statusCode != 200) {
    //   _showError('인증 코드가 올바르지 않아요');
    //   setState(() => _isLoading = false);
    //   return;
    // }

    await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이
    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Future<void> _resend() async {
    // TODO: 백엔드 API 연동
    // await http.post(
    //   Uri.parse('$baseUrl/auth/send-code'),
    //   body: jsonEncode({'email': widget.email}),
    //   headers: {'Content-Type': 'application/json'},
    // );

    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    _startTimer();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('인증 코드를 다시 발송했어요'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade400,
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
          '이메일 인증',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

            // 아이콘
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // 제목
            const Text(
              '인증 코드를 입력해주세요',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // 이메일 안내
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
                children: [
                  const TextSpan(text: '아래 메일로 발송된 6자리 코드를\n입력해주세요\n'),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // 6자리 입력 박스
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_codeLength, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i < _codeLength - 1 ? 10 : 0),
                  child: _buildDigitBox(i),
                );
              }),
            ),
            const SizedBox(height: 16),

            // 타이머 + 만료 안내
            if (_isExpired)
              const Text(
                '인증 코드가 만료됐어요. 다시 받아주세요.',
                style: TextStyle(fontSize: 13, color: Color(0xFFEF4444)),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _timerText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _remainingSeconds <= 30
                          ? const Color(0xFFEF4444)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const Text(
                    ' 후 만료',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // 인증 확인 버튼 (6칸 너비 = 44*6 + 10*5 = 314)
            SizedBox(
              width: 314,
              height: 46,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: (_isFilled && !_isExpired)
                      ? AppTheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (_isFilled && !_isExpired)
                        ? AppTheme.primary
                        : const Color(0xFFD0DCEF),
                    width: 1.5,
                  ),
                ),
                child: TextButton(
                  onPressed: (_isFilled && !_isExpired && !_isLoading) ? _verify : null,
                  style: TextButton.styleFrom(
                    foregroundColor: (_isFilled && !_isExpired)
                        ? Colors.white
                        : const Color(0xFFD0DCEF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: (_isFilled && !_isExpired)
                                ? Colors.white
                                : const Color(0xFFD0DCEF),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          '인증 확인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 재발송 버튼
            TextButton(
              onPressed: _resend,
              child: const Text(
                '인증 코드 다시 받기',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    final isFocused = _focusNodes[index].hasFocus;
    final hasValue = _controllers[index].text.isNotEmpty;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (e) => _onKeyEvent(index, e),
      child: SizedBox(
        width: 44,
        height: 54,
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasValue ? AppTheme.primary : const Color(0xFFDDE4EE),
                width: hasValue ? 2 : 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            filled: true,
            fillColor: isFocused
                ? AppTheme.primary.withOpacity(0.05)
                : Colors.white,
          ),
          onChanged: (v) => _onDigitChanged(index, v),
        ),
      ),
    );
  }
}
