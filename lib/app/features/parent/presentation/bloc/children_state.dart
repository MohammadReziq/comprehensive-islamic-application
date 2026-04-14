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
  const ChildrenLoaded(this.children, {this.linkedChildIds = const {}});

  final List<ChildModel> children;

  /// معرّفات الأبناء المرتبطين بمسجد — يُجلب مع الأبناء في نفس الحدث
  final Set<String> linkedChildIds;

  @override
  List<Object?> get props => [children, linkedChildIds];
}

/// بعد إضافة ابن مع إنشاء حساب — عرض credentials مرة واحدة ثم الانتقال لـ ChildrenLoaded
class ChildrenLoadedWithCredentials extends ChildrenState {
  const ChildrenLoadedWithCredentials(this.children,
      {required this.email, required this.password, this.linkedChildIds = const {}});

  final List<ChildModel> children;
  final String email;
  final String password;

  /// معرّفات الأبناء المرتبطين بمسجد
  final Set<String> linkedChildIds;

  // لا نُضمِّن email/password في props لمنع الظهور في BLoC observer logs
  @override
  List<Object?> get props => [children, linkedChildIds];

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
