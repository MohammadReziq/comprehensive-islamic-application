// lib/app/features/competitions/presentation/bloc/competition_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/competition_repository.dart';
import 'competition_event.dart';
import 'competition_state.dart';

class CompetitionBloc extends Bloc<CompetitionEvent, CompetitionState> {
  CompetitionBloc(this._repo) : super(CompetitionInitial()) {
    on<LoadActiveCompetition>(_onLoadActive);
    on<LoadAllCompetitions>(_onLoadAll);
    on<CreateCompetition>(_onCreate);
    on<ActivateCompetition>(_onActivate);
    on<DeactivateCompetition>(_onDeactivate);
    on<LoadLeaderboard>(_onLoadLeaderboard);
  }

  final CompetitionRepository _repo;

  Future<void> _onLoadActive(
      LoadActiveCompetition event, Emitter emit) async {
    emit(CompetitionLoading());
    try {
      final active = await _repo.getActive(event.mosqueId);
      emit(CompetitionActiveLoaded(active));
    } on AppFailure catch (f) {
      emit(CompetitionError(f.messageAr));
    } catch (_) {
      emit(const CompetitionError('حدث خطأ في تحميل المسابقة'));
    }
  }

  Future<void> _onLoadAll(
      LoadAllCompetitions event, Emitter emit) async {
    emit(CompetitionLoading());
    try {
      final list = await _repo.getAllForMosque(event.mosqueId);
      emit(CompetitionListLoaded(list));
    } on AppFailure catch (f) {
      emit(CompetitionError(f.messageAr));
    } catch (_) {
      emit(const CompetitionError('حدث خطأ في تحميل المسابقات'));
    }
  }

  Future<void> _onCreate(CreateCompetition event, Emitter emit) async {
    emit(CompetitionLoading());
    try {
      await _repo.create(
        mosqueId:  event.mosqueId,
        nameAr:    event.nameAr,
        startDate: event.startDate,
        endDate:   event.endDate,
      );
      // إعادة تحميل القائمة
      final list = await _repo.getAllForMosque(event.mosqueId);
      emit(CompetitionListLoaded(list));
    } on AppFailure catch (f) {
      emit(CompetitionError(f.messageAr));
    } catch (_) {
      emit(const CompetitionError('حدث خطأ في إنشاء المسابقة'));
    }
  }

  Future<void> _onActivate(ActivateCompetition event, Emitter emit) async {
    emit(CompetitionLoading());
    try {
      await _repo.activate(event.competitionId);
      final list = await _repo.getAllForMosque(event.mosqueId);
      emit(CompetitionListLoaded(list));
    } on AppFailure catch (f) {
      emit(CompetitionError(f.messageAr));
    } catch (_) {
      emit(const CompetitionError('حدث خطأ في تفعيل المسابقة'));
    }
  }

  Future<void> _onDeactivate(
      DeactivateCompetition event, Emitter emit) async {
    emit(CompetitionLoading());
    try {
      await _repo.deactivate(event.competitionId);
      final list = await _repo.getAllForMosque(event.mosqueId);
      emit(CompetitionListLoaded(list));
    } on AppFailure catch (f) {
      emit(CompetitionError(f.messageAr));
    } catch (_) {
      emit(const CompetitionError('حدث خطأ في إيقاف المسابقة'));
    }
  }

  Future<void> _onLoadLeaderboard(
      LoadLeaderboard event, Emitter emit) async {
    emit(CompetitionLoading());
    try {
      final entries = await _repo.getLeaderboard(event.competitionId);
      emit(LeaderboardLoaded(entries));
    } on AppFailure catch (f) {
      emit(CompetitionError(f.messageAr));
    } catch (_) {
      emit(const CompetitionError('حدث خطأ في تحميل الترتيب'));
    }
  }
}
