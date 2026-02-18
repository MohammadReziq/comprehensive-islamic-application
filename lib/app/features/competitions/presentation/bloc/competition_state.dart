// lib/app/features/competitions/presentation/bloc/competition_state.dart

import 'package:equatable/equatable.dart';
import '../../../../models/competition_model.dart';

abstract class CompetitionState extends Equatable {
  const CompetitionState();
  @override
  List<Object?> get props => [];
}

class CompetitionInitial extends CompetitionState {}
class CompetitionLoading extends CompetitionState {}

class CompetitionActiveLoaded extends CompetitionState {
  final CompetitionModel? active; // null = لا توجد مسابقة نشطة
  const CompetitionActiveLoaded(this.active);
  @override
  List<Object?> get props => [active];
}

class CompetitionListLoaded extends CompetitionState {
  final List<CompetitionModel> competitions;
  const CompetitionListLoaded(this.competitions);
  @override
  List<Object?> get props => [competitions];
}

class LeaderboardLoaded extends CompetitionState {
  final List<LeaderboardEntry> entries;
  const LeaderboardLoaded(this.entries);
  @override
  List<Object?> get props => [entries];
}

class CompetitionActionSuccess extends CompetitionState {
  final String message;
  const CompetitionActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class CompetitionError extends CompetitionState {
  final String message;
  const CompetitionError(this.message);
  @override
  List<Object?> get props => [message];
}
