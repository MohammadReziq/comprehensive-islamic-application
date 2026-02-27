import 'package:equatable/equatable.dart';

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
