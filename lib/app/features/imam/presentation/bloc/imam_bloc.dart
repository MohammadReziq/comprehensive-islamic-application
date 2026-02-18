// lib/app/features/imam/presentation/bloc/imam_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/imam_repository.dart';
import 'imam_event.dart';
import 'imam_state.dart';

class ImamBloc extends Bloc<ImamEvent, ImamState> {
  ImamBloc(this._repo) : super(ImamInitial()) {
    on<LoadMosqueStats>(_onLoadStats);
    on<LoadAttendanceReport>(_onLoadReport);
    on<LoadSupervisorsPerformance>(_onLoadPerformance);
    on<UpdateMosqueSettings>(_onUpdateSettings);
    on<CancelAttendanceByImam>(_onCancelAttendance);
  }

  final ImamRepository _repo;

  Future<void> _onLoadStats(LoadMosqueStats event, Emitter emit) async {
    emit(ImamLoading());
    try {
      final stats = await _repo.getMosqueStats(event.mosqueId);
      emit(MosqueStatsLoaded(stats));
    } on AppFailure catch (f) {
      emit(ImamError(f.messageAr));
    } catch (e) {
      emit(const ImamError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onLoadReport(LoadAttendanceReport event, Emitter emit) async {
    emit(ImamLoading());
    try {
      final records = await _repo.getAttendanceReport(
        event.mosqueId,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );
      emit(AttendanceReportLoaded(records));
    } on AppFailure catch (f) {
      emit(ImamError(f.messageAr));
    } catch (e) {
      emit(const ImamError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onLoadPerformance(
      LoadSupervisorsPerformance event, Emitter emit) async {
    emit(ImamLoading());
    try {
      final supervisors = await _repo.getSupervisorsPerformance(event.mosqueId);
      emit(SupervisorsPerformanceLoaded(supervisors));
    } on AppFailure catch (f) {
      emit(ImamError(f.messageAr));
    } catch (e) {
      emit(const ImamError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onUpdateSettings(
      UpdateMosqueSettings event, Emitter emit) async {
    emit(ImamLoading());
    try {
      final mosque = await _repo.updateMosqueSettings(
        event.mosqueId,
        name: event.name,
        address: event.address,
        lat: event.lat,
        lng: event.lng,
        attendanceWindowMinutes: event.attendanceWindowMinutes,
      );
      emit(MosqueSettingsUpdated(mosque));
    } on AppFailure catch (f) {
      emit(ImamError(f.messageAr));
    } catch (e) {
      emit(const ImamError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onCancelAttendance(
      CancelAttendanceByImam event, Emitter emit) async {
    emit(ImamLoading());
    try {
      final result = await _repo.cancelAttendance(event.attendanceId);
      emit(ImamActionSuccess(result));
    } on AppFailure catch (f) {
      emit(ImamError(f.messageAr));
    } catch (e) {
      emit(const ImamError('حدث خطأ غير متوقع'));
    }
  }
}
