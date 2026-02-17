import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. 이메일 회원가입
  // (🚨 중요: 괄호 안의 email: email, password: password 가 꼭 있어야 합니다!)
  Future<void> signUp({required String email, required String password}) async {
    await _supabase.auth.signUp(
      email: email, // 👈 여기가 핵심입니다.
      password: password, // 👈 이게 없으면 '익명 가입'으로 처리되어 에러가 납니다.
    );
  }

  // 2. 이메일 로그인
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // 로그아웃
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 현재 유저 확인
  User? get currentUser => _supabase.auth.currentUser;

  // 로그인 상태 감지 스트림
  Stream<User?> get userStream =>
      _supabase.auth.onAuthStateChange.map((data) => data.session?.user);
}
