// lib/app/models/announcement_model.dart

import 'package:equatable/equatable.dart';

/// نموذج الإعلان
class AnnouncementModel extends Equatable {
  final String id;
  final String mosqueId;
  final String createdBy;
  final String title;
  final String body;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.mosqueId,
    required this.createdBy,
    required this.title,
    required this.body,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      mosqueId: json['mosque_id'] as String,
      createdBy: (json['sender_id'] ?? json['created_by']) as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mosque_id': mosqueId,
      'created_by': createdBy,
      'title': title,
      'body': body,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? mosqueId,
    String? createdBy,
    String? title,
    String? body,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      mosqueId: mosqueId ?? this.mosqueId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      body: body ?? this.body,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, mosqueId, createdBy, title, body,
        isPinned, createdAt, updatedAt,
      ];
}
