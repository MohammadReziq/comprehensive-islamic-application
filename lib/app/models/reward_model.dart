import 'package:equatable/equatable.dart';

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
