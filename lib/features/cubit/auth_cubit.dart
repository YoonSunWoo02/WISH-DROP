import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import 'package:wish_drop/features/auth/data/auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    // 앱 켜지자마자 감시 시작
    _authSubscription = _authRepository.userStream.listen((user) {
      if (user != null) {
        emit(AuthSuccess());
      } else {
        emit(AuthInitial());
      }
    });
  }

  // 로그인 요청
  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      // 🚨 명명된 매개변수(Named parameters)를 사용해야 합니다.
      await _authRepository.signIn(email: email, password: password);
    } catch (e) {
      emit(AuthError("로그인 실패: ${e.toString()}"));
    }
  }

  // 회원가입 요청f
  Future<void> signUp(String email, String password) async {
    try {
      emit(AuthLoading());
      await _authRepository.signUp(email: email, password: password);
    } catch (e) {
      emit(AuthError("회원가입 실패: ${e.toString()}"));
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
