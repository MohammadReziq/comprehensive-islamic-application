import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

/// تحميل الطلاب والحضور لصلاة معينة
class ScannerLoad extends ScannerEvent {
  const ScannerLoad({
    required this.mosqueId,
    required this.prayer,
    required this.date,
  });

  final String mosqueId;
  final Prayer prayer;
  final DateTime date;

  @override
  List<Object?> get props => [mosqueId, prayer, date];
}

/// تسجيل حضور طفل
class ScannerRecordAttendance extends ScannerEvent {
  const ScannerRecordAttendance(this.childId);

  final String childId;

  @override
  List<Object?> get props => [childId];
}

/// مسح QR وتسجيل الحضور
class ScannerScanQr extends ScannerEvent {
  const ScannerScanQr(this.qrCode);

  final String qrCode;

  @override
  List<Object?> get props => [qrCode];
}

/// إدخال رقم الطالب وتسجيل الحضور
class ScannerRecordByNumber extends ScannerEvent {
  const ScannerRecordByNumber(this.localNumber);

  final int localNumber;

  @override
  List<Object?> get props => [localNumber];
}
