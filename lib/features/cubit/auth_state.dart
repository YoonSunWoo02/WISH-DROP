import 'package:equatable/equatable.dart'; // 👈 여기 직접 import 추가

// part of 'auth_cubit.dart';  👈 이 줄을 지우세요! (삭제)

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
