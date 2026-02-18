// lib/app/models/correction_request_model.dart
// يستخدم CorrectionStatus و Prayer من app_enums.dart

import '../core/constants/app_enums.dart';

class CorrectionRequestModel {
  final String id;
  final String childId;
  final String parentId;
  final String mosqueId;
  final Prayer prayer;
  final DateTime prayerDate;
  final CorrectionStatus status;
  final String? note;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  // حقول اختيارية من JOIN
  final String? childName;
  final String? parentName;

  const CorrectionRequestModel({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.mosqueId,
    required this.prayer,
    required this.prayerDate,
    required this.status,
    this.note,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.childName,
    this.parentName,
  });

  factory CorrectionRequestModel.fromJson(Map<String, dynamic> json) {
    return CorrectionRequestModel(
      id:         json['id'] as String,
      childId:    json['child_id'] as String,
      parentId:   json['parent_id'] as String,
      mosqueId:   json['mosque_id'] as String,
      prayer:     Prayer.fromString(json['prayer'] as String),
      prayerDate: DateTime.parse(json['prayer_date'] as String),
      status:     CorrectionStatus.fromString(json['status'] as String),
      note:       json['note'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt:  DateTime.parse(json['created_at'] as String),
      childName:  json['child_name'] as String?,
      parentName: json['parent_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'child_id':    childId,
    'parent_id':   parentId,
    'mosque_id':   mosqueId,
    'prayer':      prayer.value,
    'prayer_date': _dateStr(prayerDate),
    'status':      status.value,
    'note':        note,
  };

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
