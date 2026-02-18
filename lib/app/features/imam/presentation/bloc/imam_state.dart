// lib/app/features/imam/presentation/bloc/imam_state.dart

import 'package:equatable/equatable.dart';
import '../../../../models/mosque_model.dart';

abstract class ImamState extends Equatable {
  const ImamState();
  @override
  List<Object?> get props => [];
}

class ImamInitial extends ImamState {}

class ImamLoading extends ImamState {}

/// إحصائيات المسجد محمّلة
class MosqueStatsLoaded extends ImamState {
  final Map<String, dynamic> stats;
  const MosqueStatsLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

/// تقرير الحضور محمّل
class AttendanceReportLoaded extends ImamState {
  final List<Map<String, dynamic>> records;
  const AttendanceReportLoaded(this.records);
  @override
  List<Object?> get props => [records];
}

/// أداء المشرفين محمّل
class SupervisorsPerformanceLoaded extends ImamState {
  final List<Map<String, dynamic>> supervisors;
  const SupervisorsPerformanceLoaded(this.supervisors);
  @override
  List<Object?> get props => [supervisors];
}

/// تم تحديث إعدادات المسجد
class MosqueSettingsUpdated extends ImamState {
  final MosqueModel mosque;
  const MosqueSettingsUpdated(this.mosque);
  @override
  List<Object?> get props => [mosque];
}

/// نجاح إجراء عام
class ImamActionSuccess extends ImamState {
  final String message;
  const ImamActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// خطأ
class ImamError extends ImamState {
  final String message;
  const ImamError(this.message);
  @override
  List<Object?> get props => [message];
}
