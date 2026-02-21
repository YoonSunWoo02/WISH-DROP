import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_drop/core/theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // 입력값 제어 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 비밀번호 보이기/숨기기 상태 변수
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isTermsAgreed = false; // 약관 동의 상태
  bool _isLoading = false; // 로딩 상태

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 📝 Supabase 회원가입 로직
  Future<void> _signUp() async {
    // 1. 유효성 검사 (빈칸 등)
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showFailureDialog("모든 정보를 입력해주세요.");
      return;
    }

    if (!_isTermsAgreed) {
      _showFailureDialog("약관에 동의해주세요.");
      return;
    }

    // 2. 비밀번호 일치 확인
    if (_passwordController.text != _confirmPasswordController.text) {
      _showFailureDialog("비밀번호가 일치하지 않습니다.");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showFailureDialog("비밀번호는 6자 이상이어야 합니다.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Supabase 회원가입 요청
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'nickname': _nameController.text.trim()},
      );

      if (mounted && response.user != null) {
        _showSuccessDialog();
      }
    } on AuthException catch (e) {
      // ✨ [수정됨] 영문 에러 메시지를 한글로 변환
      String errorMessage = e.message;
      if (e.message.contains("User already registered")) {
        errorMessage = "이미 가입된 이메일이 존재합니다.";
      }

      if (mounted) _showFailureDialog(errorMessage);
    } catch (e) {
      if (mounted) _showFailureDialog(); // 기본 에러 메시지 사용
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎨 [HTML 디자인 반영] 가입 실패 다이얼로그
  void _showFailureDialog([String? specificError]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘 영역
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2), // red-50
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ), // error-red
              ),
              const SizedBox(height: 20),

              // 텍스트 영역
              const Text(
                "회원가입 실패",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                specificError ?? "이미 가입된 이메일이거나\n서버 오류입니다.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textBody,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // 버튼 영역
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "다시 시도",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 팝업 닫기
                    Navigator.pop(context); // 로그인 화면으로 돌아가기 (취소)
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textBody,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "취소",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 가입 성공 팝업
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "가입 완료!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "위시드롭의 회원이 되신 것을\n환영합니다.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textBody,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 팝업 닫기
                    Navigator.pop(context); // 로그인 화면으로 이동
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "로그인하러 가기",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text("회원가입", style: AppTheme.textTheme.headlineLarge),
                        const SizedBox(height: 12),
                        Text(
                          "함께 만드는 선물, 위시 드롭에 오신 것을 환영합니다.",
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textBody,
                          ),
                        ),
                        const SizedBox(height: 40),

                        _buildInputField("이름", "성함을 입력하세요", _nameController),
                        const SizedBox(height: 24),
                        _buildInputField(
                          "이메일",
                          "example@email.com",
                          _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),

                        // 비밀번호 필드 (눈 아이콘 기능)
                        _buildInputField(
                          "비밀번호",
                          "8자 이상 입력하세요",
                          _passwordController,
                          isPassword: true,
                          isObscure: !_isPasswordVisible,
                          onToggleVisibility: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 비밀번호 확인 필드
                        _buildInputField(
                          "비밀번호 확인",
                          "비밀번호를 한 번 더 입력하세요",
                          _confirmPasswordController,
                          isPassword: true,
                          isObscure: !_isConfirmPasswordVisible,
                          onToggleVisibility: () => setState(
                            () => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 약관 동의
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _isTermsAgreed,
                                onChanged: (v) =>
                                    setState(() => _isTermsAgreed = v ?? false),
                                activeColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: AppTheme.textBody,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "이용약관",
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: " 및 "),
                                    TextSpan(
                                      text: "개인정보 처리방침",
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: "에 동의합니다"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),
                        const SizedBox(height: 20),

                        // 가입하기 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "가입하기",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "이미 계정이 있으신가요?",
                              style: TextStyle(
                                color: AppTheme.textBody,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "로그인",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppTheme.textBody,
            letterSpacing: 0.5,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[300]),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
