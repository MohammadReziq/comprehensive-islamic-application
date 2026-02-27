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
