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

/// إنشاء مسجد جديد
class MosqueCreate extends MosqueEvent {
  const MosqueCreate({required this.name, this.address});

  final String name;
  final String? address;

  @override
  List<Object?> get props => [name, address];
}

/// الانضمام بكود الدعوة
class MosqueJoinByCode extends MosqueEvent {
  const MosqueJoinByCode(this.inviteCode);

  final String inviteCode;

  @override
  List<Object?> get props => [inviteCode];
}
