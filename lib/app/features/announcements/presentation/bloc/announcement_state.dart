// lib/app/features/announcements/presentation/bloc/announcement_state.dart

import 'package:equatable/equatable.dart';
import '../../../../models/announcement_model.dart';

abstract class AnnouncementState extends Equatable {
  const AnnouncementState();
  @override
  List<Object?> get props => [];
}

class AnnouncementInitial extends AnnouncementState {}

class AnnouncementLoading extends AnnouncementState {}

/// إعلانات محمّلة
class AnnouncementsLoaded extends AnnouncementState {
  final List<AnnouncementModel> announcements;
  final Set<String> readIds;
  const AnnouncementsLoaded(this.announcements, {this.readIds = const {}});
  @override
  List<Object?> get props => [announcements, readIds];
}

/// نجاح إجراء
class AnnouncementActionSuccess extends AnnouncementState {
  final String message;
  const AnnouncementActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// خطأ
class AnnouncementError extends AnnouncementState {
  final String message;
  const AnnouncementError(this.message);
  @override
  List<Object?> get props => [message];
}
