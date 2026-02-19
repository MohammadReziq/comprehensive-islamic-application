// lib/app/models/competition_model.dart

class CompetitionModel {
  final String id;
  final String mosqueId;
  final String nameAr;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  const CompetitionModel({
    required this.id,
    required this.mosqueId,
    required this.nameAr,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id:         json['id'] as String,
      mosqueId:   json['mosque_id'] as String,
      nameAr:     json['name_ar'] as String,
      startDate:  DateTime.parse(json['start_date'] as String),
      endDate:    DateTime.parse(json['end_date'] as String),
      isActive:   json['is_active'] as bool? ?? false,
      createdBy:  json['created_by'] as String,
      createdAt:  DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mosque_id': mosqueId,
      'name_ar': nameAr,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isOngoing {
    final now = DateTime.now();
    return isActive &&
        !now.isBefore(startDate) &&
        !now.isAfter(endDate.add(const Duration(days: 1)));
  }

  String get dateRangeAr {
    String fmt(DateTime d) =>
        '${d.day}/${d.month}/${d.year}';
    return '${fmt(startDate)} — ${fmt(endDate)}';
  }
}

/// ترتيب طفل في المسابقة
class LeaderboardEntry {
  final String childId;
  final String childName;
  final int totalPoints;
  final int attendanceCount;
  final int rank;

  const LeaderboardEntry({
    required this.childId,
    required this.childName,
    required this.totalPoints,
    required this.attendanceCount,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) {
    return LeaderboardEntry(
      childId:         json['child_id'] as String,
      childName:       json['child_name'] as String? ?? 'غير معروف',
      totalPoints:     (json['total_points'] as num?)?.toInt() ?? 0,
      attendanceCount: (json['attendance_count'] as num?)?.toInt() ?? 0,
      rank:            rank,
    );
  }
}
