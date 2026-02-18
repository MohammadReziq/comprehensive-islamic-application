// lib/app/features/super_admin/presentation/bloc/admin_state.dart

import 'package:equatable/equatable.dart';
import '../../../../models/mosque_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

/// إحصائيات النظام
class SystemStatsLoaded extends AdminState {
  final Map<String, dynamic> stats;
  const SystemStatsLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

/// قائمة المساجد
class MosquesLoaded extends AdminState {
  final List<MosqueModel> mosques;
  const MosquesLoaded(this.mosques);
  @override
  List<Object?> get props => [mosques];
}

/// قائمة المستخدمين
class UsersLoaded extends AdminState {
  final List<Map<String, dynamic>> users;
  const UsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

/// نجاح إجراء
class AdminActionSuccess extends AdminState {
  final String message;
  const AdminActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// خطأ
class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}
