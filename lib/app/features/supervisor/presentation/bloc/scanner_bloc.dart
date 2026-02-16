import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salati_hayati/app/core/constants/app_enums.dart';
import '../../data/repositories/supervisor_repository.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc(this._repo) : super(const ScannerInitial()) {
    on<ScannerLoad>(_onLoad);
    on<ScannerRecordAttendance>(_onRecordAttendance);
    on<ScannerScanQr>(_onScanQr);
    on<ScannerRecordByNumber>(_onRecordByNumber);
  }

  final SupervisorRepository _repo;

  String? _mosqueId;
  Prayer? _prayer;
  DateTime? _date;

  Future<void> _onLoad(ScannerLoad e, Emitter<ScannerState> emit) async {
    _mosqueId = e.mosqueId;
    _prayer = e.prayer;
    _date = e.date;
    emit(const ScannerLoading());
    try {
      final students = await _repo.getMosqueStudents(e.mosqueId);
      final recorded = await _repo.getRecordedChildIdsForPrayer(
        mosqueId: e.mosqueId,
        prayer: e.prayer,
        date: e.date,
      );
      emit(
        ScannerReady(
          students: students,
          recordedChildIds: recorded,
          prayer: e.prayer,
          date: e.date,
        ),
      );
    } catch (err) {
      emit(ScannerError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRecordAttendance(
    ScannerRecordAttendance e,
    Emitter<ScannerState> emit,
  ) async {
    final mosqueId = _mosqueId;
    final prayer = _prayer;
    final date = _date;
    if (mosqueId == null ||
        prayer == null ||
        date == null ||
        state is! ScannerReady)
      return;
    try {
      await _repo.recordAttendance(
        mosqueId: mosqueId,
        childId: e.childId,
        prayer: prayer,
        date: date,
      );
      final current = state as ScannerReady;
      final newRecorded = {...current.recordedChildIds, e.childId};
      emit(
        ScannerReady(
          students: current.students,
          recordedChildIds: newRecorded,
          prayer: current.prayer,
          date: current.date,
        ),
      );
    } catch (_) {
      // keep state, could emit error
    }
  }

  Future<void> _onScanQr(ScannerScanQr e, Emitter<ScannerState> emit) async {
    final mosqueId = _mosqueId;
    if (mosqueId == null) return;
    try {
      final child = await _repo.findChildByQrCode(e.qrCode, mosqueId);
      if (child != null) {
        add(ScannerRecordAttendance(child.id));
      }
    } catch (_) {}
  }

  Future<void> _onRecordByNumber(
    ScannerRecordByNumber e,
    Emitter<ScannerState> emit,
  ) async {
    final mosqueId = _mosqueId;
    if (mosqueId == null) return;
    try {
      final child = await _repo.findChildByLocalNumber(e.localNumber, mosqueId);
      if (child != null) {
        add(ScannerRecordAttendance(child.id));
      }
    } catch (_) {}
  }
}
