import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/child_repository.dart';
import 'children_event.dart';
import 'children_state.dart';

class ChildrenBloc extends Bloc<ChildrenEvent, ChildrenState> {
  ChildrenBloc(this._repo) : super(const ChildrenInitial()) {
    on<ChildrenLoad>(_onLoad);
    on<ChildrenAdd>(_onAdd);
    on<ChildrenCredentialsShown>(_onCredentialsShown);
  }

  final ChildRepository _repo;

  Future<void> _onLoad(ChildrenLoad e, Emitter<ChildrenState> emit) async {
    emit(const ChildrenLoading());
    try {
      final list = await _repo.getMyChildren();
      emit(ChildrenLoaded(list));
    } catch (err) {
      emit(ChildrenError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onAdd(ChildrenAdd e, Emitter<ChildrenState> emit) async {
    try {
      final result = await _repo.addChild(
        name: e.name,
        age: e.age,
        email: e.email,
        password: e.password,
      );
      if (result.email != null && result.password != null) {
        emit(ChildrenLoadedWithCredentials(
          await _repo.getMyChildren(),
          email: result.email!,
          password: result.password!,
        ));
      } else {
        add(const ChildrenLoad());
      }
    } catch (err) {
      emit(ChildrenError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onCredentialsShown(ChildrenCredentialsShown e, Emitter<ChildrenState> emit) {
    final state = this.state;
    if (state is ChildrenLoadedWithCredentials) {
      emit(ChildrenLoaded(state.children));
    }
  }
}
