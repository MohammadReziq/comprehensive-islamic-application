import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../models/mosque_model.dart';

abstract class MosqueState extends Equatable {
  const MosqueState();

  @override
  List<Object?> get props => [];
}

class MosqueInitial extends MosqueState {
  const MosqueInitial();
}

class MosqueLoading extends MosqueState {
  const MosqueLoading();
}

class MosqueLoaded extends MosqueState {
  const MosqueLoaded(this.mosques);

  final List<MosqueModel> mosques;

  bool get hasApproved => mosques.any((m) => m.status == MosqueStatus.approved);
  bool get hasPending => mosques.any((m) => m.status == MosqueStatus.pending);

  @override
  List<Object?> get props => [mosques];
}

class MosqueError extends MosqueState {
  const MosqueError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// تم إرسال طلب الانضمام (بانتظار موافقة الإمام)
class MosqueJoinRequestSent extends MosqueState {
  const MosqueJoinRequestSent([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}
