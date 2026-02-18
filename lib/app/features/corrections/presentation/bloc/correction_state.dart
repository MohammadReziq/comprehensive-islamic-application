// lib/app/features/corrections/presentation/bloc/correction_state.dart

import 'package:equatable/equatable.dart';
import '../../../../models/correction_request_model.dart';

abstract class CorrectionState extends Equatable {
  const CorrectionState();
  @override
  List<Object?> get props => [];
}

class CorrectionInitial extends CorrectionState {}

class CorrectionLoading extends CorrectionState {}

class CorrectionLoaded extends CorrectionState {
  final List<CorrectionRequestModel> requests;
  const CorrectionLoaded(this.requests);
  @override
  List<Object?> get props => [requests];
}

class CorrectionActionSuccess extends CorrectionState {
  final String message;
  const CorrectionActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class CorrectionError extends CorrectionState {
  final String message;
  const CorrectionError(this.message);
  @override
  List<Object?> get props => [message];
}
