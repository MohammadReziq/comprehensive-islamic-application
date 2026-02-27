import 'package:equatable/equatable.dart';

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
