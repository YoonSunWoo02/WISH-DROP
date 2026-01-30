import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import 'package:wish_drop/features/data/auth_repository.dart';

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
      await _authRepository.signIn(email: email, password: password);
    } catch (e) {
      emit(AuthError("로그인 실패: ${e.toString()}"));
    }
  }

  // 회원가입 요청
  Future<void> signUp(String email, String password) async {
    try {
      emit(AuthLoading());
      await _authRepository.signUp(email: email, password: password);
      // 회원가입 성공하면 보통 바로 로그인이 되거나, 로그인하라고 안내함.
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
