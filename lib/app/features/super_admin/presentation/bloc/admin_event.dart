// lib/app/features/super_admin/presentation/bloc/admin_event.dart

import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

/// تحميل إحصائيات النظام
class LoadSystemStats extends AdminEvent {
  const LoadSystemStats();
}

/// تحميل كل المساجد (مع فلتر اختياري)
class LoadAllMosques extends AdminEvent {
  final MosqueStatus? status;
  const LoadAllMosques({this.status});
  @override
  List<Object?> get props => [status];
}

/// تعليق مسجد
class SuspendMosque extends AdminEvent {
  final String mosqueId;
  const SuspendMosque(this.mosqueId);
  @override
  List<Object?> get props => [mosqueId];
}

/// إعادة تفعيل مسجد
class ReactivateMosque extends AdminEvent {
  final String mosqueId;
  const ReactivateMosque(this.mosqueId);
  @override
  List<Object?> get props => [mosqueId];
}

/// تحميل كل المستخدمين (مع فلتر اختياري)
class LoadAllUsers extends AdminEvent {
  final UserRole? role;
  const LoadAllUsers({this.role});
  @override
  List<Object?> get props => [role];
}

/// تغيير دور مستخدم
class UpdateUserRole extends AdminEvent {
  final String userId;
  final UserRole newRole;
  const UpdateUserRole({required this.userId, required this.newRole});
  @override
  List<Object?> get props => [userId, newRole];
}

/// تغيير إمام مسجد
class ChangeImam extends AdminEvent {
  final String mosqueId;
  final String newOwnerId;
  const ChangeImam({required this.mosqueId, required this.newOwnerId});
  @override
  List<Object?> get props => [mosqueId, newOwnerId];
}

/// حظر مستخدم
class BanUser extends AdminEvent {
  final String userId;
  const BanUser(this.userId);
  @override
  List<Object?> get props => [userId];
}
