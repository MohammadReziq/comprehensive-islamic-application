import 'package:equatable/equatable.dart';

/// أحداث المصادقة
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// فحص حالة Auth عند بدء التطبيق
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// تسجيل دخول بالإيميل
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// إنشاء حساب جديد
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'parent',
  });

  @override
  List<Object?> get props => [name, email, password, role];
}

/// تسجيل خروج
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
