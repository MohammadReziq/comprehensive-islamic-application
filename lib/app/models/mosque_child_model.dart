import 'package:equatable/equatable.dart';
import '../core/constants/app_enums.dart';

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
