import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';
import '../../data/models/mosque_student_model.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {
  const ScannerInitial();
}

class ScannerLoading extends ScannerState {
  const ScannerLoading();
}

class ScannerReady extends ScannerState {
  const ScannerReady({
    required this.students,
    required this.recordedChildIds,
    required this.prayer,
    required this.date,
    this.scanMessage,
  });

  final List<MosqueStudentModel> students;
  final Set<String> recordedChildIds;
  final Prayer prayer;
  final DateTime date;
  /// رسالة بعد مسح QR (نجاح أو فشل) — تُعرض مرة ثم تُمسح
  final String? scanMessage;

  bool isRecorded(String childId) => recordedChildIds.contains(childId);

  @override
  List<Object?> get props => [students, recordedChildIds, prayer, date, scanMessage];
}

class ScannerError extends ScannerState {
  const ScannerError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
