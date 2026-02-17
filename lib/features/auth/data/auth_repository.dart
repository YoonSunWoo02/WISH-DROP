import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // ✅ 실시간 인증 상태 스트림 (Cubit에서 listen할 대상)
  Stream<User?> get userStream =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  // 로그인 (매개변수 이름을 email, password로 명확히 지정)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 회원가입
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // 로그아웃
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 현재 유저 확인
  User? get currentUser => _supabase.auth.currentUser;
}
