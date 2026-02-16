import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/mosque_repository.dart';
import 'mosque_event.dart';
import 'mosque_state.dart';

class MosqueBloc extends Bloc<MosqueEvent, MosqueState> {
  MosqueBloc(this._repo) : super(const MosqueInitial()) {
    on<MosqueLoadMyMosques>(_onLoadMyMosques);
    on<MosqueCreate>(_onCreate);
    on<MosqueJoinByCode>(_onJoinByCode);
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
      await _repo.joinByInviteCode(e.inviteCode);
      final list = await _repo.getMyMosques();
      emit(MosqueLoaded(list));
    } catch (err) {
      emit(MosqueError(err.toString().replaceFirst('Exception: ', '')));
    }
  }
}
