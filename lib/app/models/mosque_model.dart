import 'package:equatable/equatable.dart';
import '../core/constants/app_enums.dart';

/// نموذج المسجد
class MosqueModel extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String code;
  final String inviteCode;
  final String? address;
  final double? lat;
  final double? lng;
  final MosqueStatus status;
  final Map<String, dynamic>? prayerConfig;
  final DateTime createdAt;

  const MosqueModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.code,
    required this.inviteCode,
    this.address,
    this.lat,
    this.lng,
    this.status = MosqueStatus.pending,
    this.prayerConfig,
    required this.createdAt,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      inviteCode: json['invite_code'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      status: MosqueStatus.fromString(json['status'] as String? ?? 'pending'),
      prayerConfig: json['prayer_config'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'code': code,
      'invite_code': inviteCode,
      'address': address,
      'lat': lat,
      'lng': lng,
      'status': status.value,
      'prayer_config': prayerConfig,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MosqueModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? code,
    String? inviteCode,
    String? address,
    double? lat,
    double? lng,
    MosqueStatus? status,
    Map<String, dynamic>? prayerConfig,
    DateTime? createdAt,
  }) {
    return MosqueModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      code: code ?? this.code,
      inviteCode: inviteCode ?? this.inviteCode,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
      prayerConfig: prayerConfig ?? this.prayerConfig,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, ownerId, name, code, inviteCode,
        address, lat, lng, status, prayerConfig, createdAt,
      ];
}
