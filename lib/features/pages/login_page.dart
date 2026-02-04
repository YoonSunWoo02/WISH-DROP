import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_drop/features/cubit/auth_cubit.dart';
import 'package:wish_drop/features/cubit/auth_state.dart';
import 'package:wish_drop/features/data/auth_repository.dart';
import 'package:wish_drop/features/pages/home_page.dart';
import 'package:wish_drop/features/pages/signup_page.dart'; // 👈 import 추가

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 입력값을 제어하는 컨트롤러
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 비밀번호 보이기/숨기기 상태
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. AuthCubit 주입 (Repository 연결)
    return BlocProvider(
      create: (context) => AuthCubit(AuthRepository()),
      child: GestureDetector(
        // 화면 빈 곳 터치하면 키보드 내리기
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                // 에러 발생 시 스낵바 띄우기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              if (state is AuthSuccess) {
                // 로그인 성공 시 홈 화면으로 이동 (뒤로가기 방지)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              }
            },
            builder: (context, state) {
              // 로딩 중인지 확인
              final bool isLoading = state is AuthLoading;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. 로고 및 타이틀
                      const Icon(
                        Icons.card_giftcard,
                        size: 80,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Wish Drop",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "친구들과 함께하는 선물 펀딩",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 48),

                      // 3. 이메일 입력창
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "이메일",
                          hintText: "example@email.com",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. 비밀번호 입력창
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible, // 비밀번호 가리기 토글
                        decoration: InputDecoration(
                          labelText: "비밀번호",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. 로그인 버튼
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                final email = _emailController.text.trim();
                                final pw = _passwordController.text.trim();
                                if (email.isNotEmpty && pw.isNotEmpty) {
                                  context.read<AuthCubit>().login(email, pw);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "로그인",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // 6. 회원가입 구분선
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "또는",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 7. 회원가입 버튼 (Outlined Style)
                      // ... 기존 코드 ...

                      // 7. 회원가입 버튼 (Outlined Style)
                      OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // 👇 기존 코드를 지우고, 페이지 이동 코드로 변경!
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    // 중요: 회원가입 페이지에서도 큐빗을 쓸 수 있게 넘겨줍니다.
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<AuthCubit>(),
                                      child: const SignUpPage(),
                                    ),
                                  ),
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.deepPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "이메일로 회원가입",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      // ... 기존 코드 ...
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
