import 'package:equatable/equatable.dart';
import '../core/constants/app_enums.dart';

/// نموذج الحضور
class AttendanceModel extends Equatable {
  final String id;
  final String childId;
  final String? mosqueId;
  final String recordedById;
  final Prayer prayer;
  final LocationType locationType;
  final int pointsEarned;
  final DateTime prayerDate;
  final bool syncedOffline;
  final DateTime recordedAt;

  const AttendanceModel({
    required this.id,
    required this.childId,
    this.mosqueId,
    required this.recordedById,
    required this.prayer,
    required this.locationType,
    required this.pointsEarned,
    required this.prayerDate,
    this.syncedOffline = false,
    required this.recordedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      childId: json['child_id'] as String,
      mosqueId: json['mosque_id'] as String?,
      recordedById: json['recorded_by_id'] as String,
      prayer: Prayer.fromString(json['prayer'] as String),
      locationType: LocationType.fromString(json['location_type'] as String),
      pointsEarned: json['points_earned'] as int,
      prayerDate: DateTime.parse(json['prayer_date'] as String),
      syncedOffline: json['synced_offline'] as bool? ?? false,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'mosque_id': mosqueId,
      'recorded_by_id': recordedById,
      'prayer': prayer.value,
      'location_type': locationType.value,
      'points_earned': pointsEarned,
      'prayer_date': prayerDate.toIso8601String().split('T').first,
      'synced_offline': syncedOffline,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? childId,
    String? mosqueId,
    String? recordedById,
    Prayer? prayer,
    LocationType? locationType,
    int? pointsEarned,
    DateTime? prayerDate,
    bool? syncedOffline,
    DateTime? recordedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      mosqueId: mosqueId ?? this.mosqueId,
      recordedById: recordedById ?? this.recordedById,
      prayer: prayer ?? this.prayer,
      locationType: locationType ?? this.locationType,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      prayerDate: prayerDate ?? this.prayerDate,
      syncedOffline: syncedOffline ?? this.syncedOffline,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, childId, mosqueId, recordedById, prayer,
        locationType, pointsEarned, prayerDate, syncedOffline, recordedAt,
      ];
}
