import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_enums.dart';
import '../../data/repositories/mosque_repository.dart';
import 'mosque_event.dart';
import 'mosque_state.dart';

class MosqueBloc extends Bloc<MosqueEvent, MosqueState> {
  MosqueBloc(this._repo) : super(const MosqueInitial()) {
    on<MosqueLoadMyMosques>(_onLoadMyMosques);
    on<MosqueCreate>(_onCreate);
    on<MosqueJoinByCode>(_onJoinByCode);
    on<MosqueLoadPendingForAdmin>(_onLoadPendingForAdmin);
    on<MosqueApproveRequest>(_onApproveRequest);
    on<MosqueRejectRequest>(_onRejectRequest);
  }

  final MosqueRepository _repo;

  Future<void> _onLoadMyMosques(MosqueLoadMyMosques e, Emitter<MosqueState> emit) async {
    emit(const MosqueLoading());
    try {
      final list = await _repo.getMyMosques();
      emit(MosqueLoaded(list));
    } catch (err) {
      emit(MosqueError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onCreate(MosqueCreate e, Emitter<MosqueState> emit) async {
    emit(const MosqueLoading());
    try {
      await _repo.createMosque(name: e.name, address: e.address);
      final list = await _repo.getMyMosques();
      emit(MosqueLoaded(list));
    } catch (err) {
      emit(MosqueError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onJoinByCode(MosqueJoinByCode e, Emitter<MosqueState> emit) async {
    emit(const MosqueLoading());
    try {
      await _repo.requestToJoinByInviteCode(e.inviteCode);
      emit(const MosqueJoinRequestSent('تم إرسال طلب الانضمام. سيتم إعلامك عند الموافقة.'));
    } catch (err) {
      emit(MosqueError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadPendingForAdmin(MosqueLoadPendingForAdmin e, Emitter<MosqueState> emit) async {
    emit(const MosqueLoading());
    try {
      final list = await _repo.getPendingMosquesForAdmin();
      emit(MosqueLoaded(list));
    } catch (err) {
      emit(MosqueError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onApproveRequest(MosqueApproveRequest e, Emitter<MosqueState> emit) async {
    final current = state;
    try {
      await _repo.updateMosqueStatus(e.mosqueId, MosqueStatus.approved);
      if (current is MosqueLoaded) {
        final list = current.mosques.where((m) => m.id != e.mosqueId).toList();
        emit(MosqueLoaded(list));
      } else {
        add(const MosqueLoadPendingForAdmin());
      }
    } catch (err) {
      emit(MosqueError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRejectRequest(MosqueRejectRequest e, Emitter<MosqueState> emit) async {
    final current = state;
    try {
      await _repo.updateMosqueStatus(e.mosqueId, MosqueStatus.rejected);
      if (current is MosqueLoaded) {
        final list = current.mosques.where((m) => m.id != e.mosqueId).toList();
        emit(MosqueLoaded(list));
      } else {
        add(const MosqueLoadPendingForAdmin());
      }
    } catch (err) {
      emit(MosqueError(err.toString().replaceFirst('Exception: ', '')));
    }
  }
}
