import 'package:equatable/equatable.dart';
import '../../../../models/child_model.dart';

abstract class ChildrenState extends Equatable {
  const ChildrenState();

  @override
  List<Object?> get props => [];
}

class ChildrenInitial extends ChildrenState {
  const ChildrenInitial();
}

class ChildrenLoading extends ChildrenState {
  const ChildrenLoading();
}

class ChildrenLoaded extends ChildrenState {
  const ChildrenLoaded(this.children);

  final List<ChildModel> children;

  @override
  List<Object?> get props => [children];
}

/// بعد إضافة ابن مع إنشاء حساب — عرض credentials مرة واحدة ثم الانتقال لـ ChildrenLoaded
class ChildrenLoadedWithCredentials extends ChildrenState {
  const ChildrenLoadedWithCredentials(this.children,
      {required this.email, required this.password});

  final List<ChildModel> children;
  final String email;
  final String password;

  // لا نُضمِّن email/password في props لمنع الظهور في BLoC observer logs
  @override
  List<Object?> get props => [children];

  @override
  String toString() =>
      'ChildrenLoadedWithCredentials { children: ${children.length}, email: ****, password: **** }';
}

class ChildrenError extends ChildrenState {
  const ChildrenError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
