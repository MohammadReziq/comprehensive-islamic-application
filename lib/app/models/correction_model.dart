import 'package:equatable/equatable.dart';
import '../core/constants/app_enums.dart';

/// نموذج طلب التصحيح
class CorrectionModel extends Equatable {
  final String id;
  final String childId;
  final String parentId;
  final String mosqueId;
  final Prayer prayer;
  final DateTime prayerDate;
  final CorrectionStatus status;
  final String? note;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const CorrectionModel({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.mosqueId,
    required this.prayer,
    required this.prayerDate,
    this.status = CorrectionStatus.pending,
    this.note,
    this.reviewedBy,
    required this.createdAt,
    this.reviewedAt,
  });

  factory CorrectionModel.fromJson(Map<String, dynamic> json) {
    return CorrectionModel(
      id: json['id'] as String,
      childId: json['child_id'] as String,
      parentId: json['parent_id'] as String,
      mosqueId: json['mosque_id'] as String,
      prayer: Prayer.fromString(json['prayer'] as String),
      prayerDate: DateTime.parse(json['prayer_date'] as String),
      status:
          CorrectionStatus.fromString(json['status'] as String? ?? 'pending'),
      note: json['note'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'parent_id': parentId,
        'mosque_id': mosqueId,
        'prayer': prayer.value,
        'prayer_date': prayerDate.toIso8601String().split('T').first,
        'status': status.value,
        'note': note,
        'reviewed_by': reviewedBy,
        'created_at': createdAt.toIso8601String(),
        'reviewed_at': reviewedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id, childId, parentId, mosqueId, prayer,
        prayerDate, status, note, reviewedBy, createdAt, reviewedAt,
      ];
}
