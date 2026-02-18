// lib/app/features/competitions/presentation/bloc/competition_event.dart

import 'package:equatable/equatable.dart';

abstract class CompetitionEvent extends Equatable {
  const CompetitionEvent();
  @override
  List<Object?> get props => [];
}

class LoadActiveCompetition extends CompetitionEvent {
  final String mosqueId;
  const LoadActiveCompetition(this.mosqueId);
  @override
  List<Object?> get props => [mosqueId];
}

class LoadAllCompetitions extends CompetitionEvent {
  final String mosqueId;
  const LoadAllCompetitions(this.mosqueId);
  @override
  List<Object?> get props => [mosqueId];
}

class CreateCompetition extends CompetitionEvent {
  final String mosqueId;
  final String nameAr;
  final DateTime startDate;
  final DateTime endDate;
  const CreateCompetition({
    required this.mosqueId,
    required this.nameAr,
    required this.startDate,
    required this.endDate,
  });
  @override
  List<Object?> get props => [mosqueId, nameAr, startDate, endDate];
}

class ActivateCompetition extends CompetitionEvent {
  final String competitionId;
  final String mosqueId;
  const ActivateCompetition(this.competitionId, this.mosqueId);
  @override
  List<Object?> get props => [competitionId, mosqueId];
}

class DeactivateCompetition extends CompetitionEvent {
  final String competitionId;
  final String mosqueId;
  const DeactivateCompetition(this.competitionId, this.mosqueId);
  @override
  List<Object?> get props => [competitionId, mosqueId];
}

class LoadLeaderboard extends CompetitionEvent {
  final String competitionId;
  const LoadLeaderboard(this.competitionId);
  @override
  List<Object?> get props => [competitionId];
}
