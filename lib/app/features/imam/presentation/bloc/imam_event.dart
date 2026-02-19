// lib/app/features/imam/presentation/bloc/imam_event.dart

import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';

abstract class ImamEvent extends Equatable {
  const ImamEvent();
  @override
  List<Object?> get props => [];
}

/// تحميل إحصائيات المسجد
class LoadMosqueStats extends ImamEvent {
  final String mosqueId;
  const LoadMosqueStats(this.mosqueId);
  @override
  List<Object?> get props => [mosqueId];
}

/// تحميل تقرير الحضور لفترة
class LoadAttendanceReport extends ImamEvent {
  final String mosqueId;
  final DateTime fromDate;
  final DateTime toDate;
  const LoadAttendanceReport({
    required this.mosqueId,
    required this.fromDate,
    required this.toDate,
  });
  @override
  List<Object?> get props => [mosqueId, fromDate, toDate];
}

/// تحميل أداء المشرفين
class LoadSupervisorsPerformance extends ImamEvent {
  final String mosqueId;
  const LoadSupervisorsPerformance(this.mosqueId);
  @override
  List<Object?> get props => [mosqueId];
}

/// تحديث إعدادات المسجد
class UpdateMosqueSettings extends ImamEvent {
  final String mosqueId;
  final String? name;
  final String? address;
  final double? lat;
  final double? lng;
  final int? attendanceWindowMinutes;
  const UpdateMosqueSettings({
    required this.mosqueId,
    this.name,
    this.address,
    this.lat,
    this.lng,
    this.attendanceWindowMinutes,
  });
  @override
  List<Object?> get props => [mosqueId, name, address, lat, lng, attendanceWindowMinutes];
}

/// تحديث نقاط الصلوات للمسجد (الإمام فقط)
class UpdateMosquePrayerPoints extends ImamEvent {
  final String mosqueId;
  final Map<Prayer, int> points;
  const UpdateMosquePrayerPoints(this.mosqueId, this.points);
  @override
  List<Object?> get props => [mosqueId, points];
}

/// إلغاء حضور
class CancelAttendanceByImam extends ImamEvent {
  final String attendanceId;
  const CancelAttendanceByImam(this.attendanceId);
  @override
  List<Object?> get props => [attendanceId];
}
