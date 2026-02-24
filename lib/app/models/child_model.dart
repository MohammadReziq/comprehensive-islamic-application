import 'package:equatable/equatable.dart';

/// نموذج الابن
class ChildModel extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String qrCode;
  final String? avatarUrl;
  final int totalPoints;
  final int currentStreak;
  final int bestStreak;
  final DateTime createdAt;

  const ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    required this.qrCode,
    this.avatarUrl,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.createdAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      qrCode: json['qr_code'] as String,
      avatarUrl: json['avatar_url'] as String?,
      totalPoints: json['total_points'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'age': age,
      'qr_code': qrCode,
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChildModel copyWith({
    String? id,
    String? parentId,
    String? name,
    int? age,
    String? qrCode,
    String? avatarUrl,
    int? totalPoints,
    int? currentStreak,
    int? bestStreak,
    DateTime? createdAt,
  }) {
    return ChildModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      qrCode: qrCode ?? this.qrCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, parentId, name, age, qrCode,
        avatarUrl, totalPoints, currentStreak, bestStreak, createdAt,
      ];
}
