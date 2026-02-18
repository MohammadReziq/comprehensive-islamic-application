// lib/app/features/corrections/presentation/bloc/correction_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/correction_repository.dart';
import 'correction_event.dart';
import 'correction_state.dart';

class CorrectionBloc extends Bloc<CorrectionEvent, CorrectionState> {
  CorrectionBloc(this._repo) : super(CorrectionInitial()) {
    on<LoadPendingCorrections>(_onLoadPending);
    on<LoadMyCorrections>(_onLoadMine);
    on<CreateCorrectionRequest>(_onCreate);
    on<ApproveCorrection>(_onApprove);
    on<RejectCorrection>(_onReject);
  }

  final CorrectionRepository _repo;

  Future<void> _onLoadPending(
      LoadPendingCorrections event, Emitter emit) async {
    emit(CorrectionLoading());
    try {
      final list = await _repo.getPendingForMosque(event.mosqueId);
      emit(CorrectionLoaded(list));
    } on AppFailure catch (f) {
      emit(CorrectionError(f.messageAr));
    } catch (e) {
      emit(CorrectionError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onLoadMine(LoadMyCorrections event, Emitter emit) async {
    emit(CorrectionLoading());
    try {
      final list = await _repo.getMyRequests();
      emit(CorrectionLoaded(list));
    } on AppFailure catch (f) {
      emit(CorrectionError(f.messageAr));
    } catch (e) {
      emit(CorrectionError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onCreate(
      CreateCorrectionRequest event, Emitter emit) async {
    emit(CorrectionLoading());
    try {
      await _repo.createRequest(
        childId:    event.childId,
        mosqueId:   event.mosqueId,
        prayer:     event.prayer,
        prayerDate: event.prayerDate,
        note:       event.note,
      );
      emit(const CorrectionActionSuccess('تم إرسال طلب التصحيح بنجاح'));
    } on AppFailure catch (f) {
      emit(CorrectionError(f.messageAr));
    } catch (e) {
      emit(CorrectionError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onApprove(ApproveCorrection event, Emitter emit) async {
    emit(CorrectionLoading());
    try {
      await _repo.approveRequest(event.requestId);
      emit(const CorrectionActionSuccess('تمت الموافقة وتسجيل الحضور'));
    } on AppFailure catch (f) {
      emit(CorrectionError(f.messageAr));
    } catch (e) {
      emit(CorrectionError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onReject(RejectCorrection event, Emitter emit) async {
    emit(CorrectionLoading());
    try {
      await _repo.rejectRequest(event.requestId, reason: event.reason);
      emit(const CorrectionActionSuccess('تم رفض الطلب'));
    } on AppFailure catch (f) {
      emit(CorrectionError(f.messageAr));
    } catch (e) {
      emit(CorrectionError('حدث خطأ غير متوقع'));
    }
  }
}
