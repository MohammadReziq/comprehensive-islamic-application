// lib/app/features/announcements/presentation/bloc/announcement_event.dart

import 'package:equatable/equatable.dart';

abstract class AnnouncementEvent extends Equatable {
  const AnnouncementEvent();
  @override
  List<Object?> get props => [];
}

/// تحميل إعلانات مسجد
class LoadAnnouncements extends AnnouncementEvent {
  final String mosqueId;
  const LoadAnnouncements(this.mosqueId);
  @override
  List<Object?> get props => [mosqueId];
}

/// إنشاء إعلان
class CreateAnnouncement extends AnnouncementEvent {
  final String mosqueId;
  final String title;
  final String body;
  final bool isPinned;
  const CreateAnnouncement({
    required this.mosqueId,
    required this.title,
    required this.body,
    this.isPinned = false,
  });
  @override
  List<Object?> get props => [mosqueId, title, body, isPinned];
}

/// تعديل إعلان
class UpdateAnnouncement extends AnnouncementEvent {
  final String announcementId;
  final String? title;
  final String? body;
  final bool? isPinned;
  const UpdateAnnouncement({
    required this.announcementId,
    this.title,
    this.body,
    this.isPinned,
  });
  @override
  List<Object?> get props => [announcementId, title, body, isPinned];
}

/// حذف إعلان
class DeleteAnnouncement extends AnnouncementEvent {
  final String announcementId;
  const DeleteAnnouncement(this.announcementId);
  @override
  List<Object?> get props => [announcementId];
}

/// تحميل إعلانات لولي الأمر (مساجد أبنائه)
class LoadForParent extends AnnouncementEvent {
  final List<String> mosqueIds;
  const LoadForParent(this.mosqueIds);
  @override
  List<Object?> get props => [mosqueIds];
}

/// تسجيل قراءة إعلان (للوالد)
class MarkAsRead extends AnnouncementEvent {
  final String announcementId;
  const MarkAsRead(this.announcementId);
  @override
  List<Object?> get props => [announcementId];
}
