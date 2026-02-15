import 'package:equatable/equatable.dart';
import '../core/constants/app_enums.dart';

/// نموذج المستخدم
class UserModel extends Equatable {
  final String id;
  final String? authId;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final String? fcmToken;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.authId,
    required this.name,
    this.email,
    this.phone,
    this.role = UserRole.parent,
    this.avatarUrl,
    this.fcmToken,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      authId: json['auth_id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'parent'),
      avatarUrl: json['avatar_url'] as String?,
      fcmToken: json['fcm_token'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'avatar_url': avatarUrl,
      'fcm_token': fcmToken,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? authId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    String? fcmToken,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, authId, name, email, phone,
        role, avatarUrl, fcmToken, isActive, createdAt,
      ];
}
