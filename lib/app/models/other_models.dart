import 'package:equatable/equatable.dart';
import '../core/constants/app_enums.dart';

/// نموذج عضوية المسجد (مشرف أو مالك) — مع اسم المستخدم عند الجلب مع join
class MosqueMemberModel extends Equatable {
  final String id;
  final String mosqueId;
  final String userId;
  final MosqueRole role;
  final DateTime joinedAt;
  final String? userName;
  final String? userEmail;

  const MosqueMemberModel({
    required this.id,
    required this.mosqueId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.userName,
    this.userEmail,
  });

  factory MosqueMemberModel.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;
    return MosqueMemberModel(
      id: json['id'] as String,
      mosqueId: json['mosque_id'] as String,
      userId: json['user_id'] as String,
      role: MosqueRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      userName: users?['name'] as String?,
      userEmail: users?['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mosque_id': mosqueId,
        'user_id': userId,
        'role': role.value,
        'joined_at': joinedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, mosqueId, userId, role, joinedAt, userName, userEmail];
}

/// حالة طلب الانضمام للمسجد
enum MosqueJoinRequestStatus {
  pending('pending', 'قيد المراجعة'),
  approved('approved', 'موافق عليه'),
  rejected('rejected', 'مرفوض');

  const MosqueJoinRequestStatus(this.value, this.nameAr);
  final String value;
  final String nameAr;

  static MosqueJoinRequestStatus fromString(String v) {
    return MosqueJoinRequestStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => MosqueJoinRequestStatus.pending,
    );
  }
}

/// نموذج طلب انضمام مشرف للمسجد
class MosqueJoinRequestModel extends Equatable {
  final String id;
  final String mosqueId;
  final String userId;
  final MosqueJoinRequestStatus status;
  final DateTime requestedAt;
  final String? userName;
  final String? userEmail;

  const MosqueJoinRequestModel({
    required this.id,
    required this.mosqueId,
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.userName,
    this.userEmail,
  });

  factory MosqueJoinRequestModel.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;
    return MosqueJoinRequestModel(
      id: json['id'] as String,
      mosqueId: json['mosque_id'] as String,
      userId: json['user_id'] as String,
      status: MosqueJoinRequestStatus.fromString(json['status'] as String? ?? 'pending'),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      userName: users?['name'] as String?,
      userEmail: users?['email'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, mosqueId, userId, status, requestedAt, userName, userEmail];
}

/// نموذج ربط الابن بالمسجد
class MosqueChildModel extends Equatable {
  final String id;
  final String mosqueId;
  final String childId;
  final MosqueType type;
  final int localNumber;
  final bool isActive;
  final DateTime joinedAt;

  const MosqueChildModel({
    required this.id,
    required this.mosqueId,
    required this.childId,
    required this.type,
    required this.localNumber,
    this.isActive = true,
    required this.joinedAt,
  });

  factory MosqueChildModel.fromJson(Map<String, dynamic> json) {
    return MosqueChildModel(
      id: json['id'] as String,
      mosqueId: json['mosque_id'] as String,
      childId: json['child_id'] as String,
      type: MosqueType.fromString(json['type'] as String),
      localNumber: json['local_number'] as int,
      isActive: json['is_active'] as bool? ?? true,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mosque_id': mosqueId,
        'child_id': childId,
        'type': type.value,
        'local_number': localNumber,
        'is_active': isActive,
        'joined_at': joinedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, mosqueId, childId, type, localNumber, isActive, joinedAt];
}

/// نموذج الشارة
class BadgeModel extends Equatable {
  final String id;
  final String childId;
  final String type;
  final String nameAr;
  final DateTime earnedAt;

  const BadgeModel({
    required this.id,
    required this.childId,
    required this.type,
    required this.nameAr,
    required this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      childId: json['child_id'] as String,
      type: json['type'] as String,
      nameAr: json['name_ar'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'type': type,
        'name_ar': nameAr,
        'earned_at': earnedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, childId, type, nameAr, earnedAt];
}

/// نموذج الجائزة
class RewardModel extends Equatable {
  final String id;
  final String childId;
  final String parentId;
  final String title;
  final int targetPoints;
  final bool isClaimed;
  final DateTime createdAt;

  const RewardModel({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.title,
    required this.targetPoints,
    this.isClaimed = false,
    required this.createdAt,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String,
      childId: json['child_id'] as String,
      parentId: json['parent_id'] as String,
      title: json['title'] as String,
      targetPoints: json['target_points'] as int,
      isClaimed: json['is_claimed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'parent_id': parentId,
        'title': title,
        'target_points': targetPoints,
        'is_claimed': isClaimed,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, childId, parentId, title, targetPoints, isClaimed, createdAt];
}

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

/// نموذج الملاحظة
class NoteModel extends Equatable {
  final String id;
  final String childId;
  final String senderId;
  final String mosqueId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NoteModel({
    required this.id,
    required this.childId,
    required this.senderId,
    required this.mosqueId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      childId: json['child_id'] as String,
      senderId: json['sender_id'] as String,
      mosqueId: json['mosque_id'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'sender_id': senderId,
        'mosque_id': mosqueId,
        'message': message,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, childId, senderId, mosqueId, message, isRead, createdAt];
}

/// نموذج الإعلان
class AnnouncementModel extends Equatable {
  final String id;
  final String mosqueId;
  final String senderId;
  final String title;
  final String body;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.mosqueId,
    required this.senderId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      mosqueId: json['mosque_id'] as String,
      senderId: json['sender_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mosque_id': mosqueId,
        'sender_id': senderId,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, mosqueId, senderId, title, body, createdAt];
}
