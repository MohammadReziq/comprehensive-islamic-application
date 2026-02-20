import 'package:equatable/equatable.dart';

abstract class MosqueEvent extends Equatable {
  const MosqueEvent();

  @override
  List<Object?> get props => [];
}

/// جلب مساجدي
class MosqueLoadMyMosques extends MosqueEvent {
  const MosqueLoadMyMosques();
}

/// إنشاء مسجد جديد — الموقع على الخريطة إلزامي
class MosqueCreate extends MosqueEvent {
  const MosqueCreate({
    required this.name,
    this.address,
    required this.lat,
    required this.lng,
  });

  final String name;
  final String? address;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [name, address, lat, lng];
}

/// الانضمام بكود الدعوة
class MosqueJoinByCode extends MosqueEvent {
  const MosqueJoinByCode(this.inviteCode);

  final String inviteCode;

  @override
  List<Object?> get props => [inviteCode];
}

/// جلب طلبات المساجد قيد المراجعة (سوبر أدمن)
class MosqueLoadPendingForAdmin extends MosqueEvent {
  const MosqueLoadPendingForAdmin();
}

/// موافقة على طلب مسجد (سوبر أدمن)
class MosqueApproveRequest extends MosqueEvent {
  const MosqueApproveRequest(this.mosqueId);

  final String mosqueId;

  @override
  List<Object?> get props => [mosqueId];
}

/// رفض طلب مسجد (سوبر أدمن)
class MosqueRejectRequest extends MosqueEvent {
  const MosqueRejectRequest(this.mosqueId);

  final String mosqueId;

  @override
  List<Object?> get props => [mosqueId];
}
