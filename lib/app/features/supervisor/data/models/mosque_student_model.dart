import 'package:equatable/equatable.dart';
import '../../../../models/child_model.dart';

/// طفل مرتبط بمسجد (مع رقمه المحلي في المسجد)
class MosqueStudentModel extends Equatable {
  const MosqueStudentModel({
    required this.child,
    required this.localNumber,
  });

  final ChildModel child;
  final int localNumber;

  @override
  List<Object?> get props => [child, localNumber];
}
