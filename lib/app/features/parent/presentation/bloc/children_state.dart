import 'package:equatable/equatable.dart';
import '../../../../models/child_model.dart';

abstract class ChildrenState extends Equatable {
  const ChildrenState();

  @override
  List<Object?> get props => [];
}

class ChildrenInitial extends ChildrenState {
  const ChildrenInitial();
}

class ChildrenLoading extends ChildrenState {
  const ChildrenLoading();
}

class ChildrenLoaded extends ChildrenState {
  const ChildrenLoaded(this.children);

  final List<ChildModel> children;

  @override
  List<Object?> get props => [children];
}

class ChildrenError extends ChildrenState {
  const ChildrenError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
