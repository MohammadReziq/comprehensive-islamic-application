// lib/app/features/super_admin/presentation/bloc/admin_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc(this._repo) : super(AdminInitial()) {
    on<LoadSystemStats>(_onLoadStats);
    on<LoadAllMosques>(_onLoadMosques);
    on<SuspendMosque>(_onSuspend);
    on<ReactivateMosque>(_onReactivate);
    on<LoadAllUsers>(_onLoadUsers);
    on<UpdateUserRole>(_onUpdateRole);
    on<ChangeImam>(_onChangeImam);
    on<BanUser>(_onBanUser);
  }

  final AdminRepository _repo;

  Future<void> _onLoadStats(LoadSystemStats event, Emitter emit) async {
    emit(AdminLoading());
    try {
      final stats = await _repo.getSystemStats();
      emit(SystemStatsLoaded(stats));
    } on AppFailure catch (f) {
      emit(AdminError(f.messageAr));
    } catch (e) {
      emit(const AdminError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onLoadMosques(LoadAllMosques event, Emitter emit) async {
    emit(AdminLoading());
    try {
      final mosques = await _repo.getAllMosques(status: event.status);
      emit(MosquesLoaded(mosques));
    } on AppFailure catch (f) {
      emit(AdminError(f.messageAr));
    } catch (e) {
      emit(const AdminError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onSuspend(SuspendMosque event, Emitter emit) async {
    emit(AdminLoading());
    try {
      await _repo.suspendMosque(event.mosqueId);
      emit(const AdminActionSuccess('تم تعليق المسجد'));
      final mosques = await _repo.getAllMosques(status: null);
      emit(MosquesLoaded(mosques));
    } on AppFailure catch (f) {
      emit(AdminError(f.messageAr));
    } catch (e) {
      emit(const AdminError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onReactivate(ReactivateMosque event, Emitter emit) async {
    emit(AdminLoading());
    try {
      await _repo.reactivateMosque(event.mosqueId);
      emit(const AdminActionSuccess('تم إعادة تفعيل المسجد'));
      final mosques = await _repo.getAllMosques(status: null);
      emit(MosquesLoaded(mosques));
    } on AppFailure catch (f) {
      emit(AdminError(f.messageAr));
    } catch (e) {
      emit(const AdminError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onLoadUsers(LoadAllUsers event, Emitter emit) async {
    emit(AdminLoading());
    try {
      final users = await _repo.getAllUsers(role: event.role);
      emit(UsersLoaded(users));
    } on AppFailure catch (f) {
      emit(AdminError(f.messageAr));
    } catch (e) {
      emit(const AdminError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onUpdateRole(UpdateUserRole event, Emitter emit) async {
    emit(AdminLoading());
    try {
      await _repo.updateUserRole(event.userId, event.newRole);
      emit(const AdminActionSuccess('تم تحديث دور المستخدم'));
    } on AppFailure catch (f) {
      emit(AdminError(f.messageAr));
    } catch (e) {
      emit(const AdminError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onChangeImam(ChangeImam event, Emitter emit) async {
    emit(AdminLoading());
    try {
      await _repo.changeImam(event.mosqueId, event.newOwnerId);
      emit(const AdminActionSuccess('تم تغيير إمام المسجد'));
    } on AppFailure catch (f) {
      emit(AdminError(f.messageAr));
    } catch (e) {
      emit(const AdminError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onBanUser(BanUser event, Emitter emit) async {
    emit(AdminLoading());
    try {
      await _repo.banUser(event.userId);
      emit(const AdminActionSuccess('تم حظر المستخدم'));
    } on AppFailure catch (f) {
      emit(AdminError(f.messageAr));
    } catch (e) {
      emit(const AdminError('حدث خطأ غير متوقع'));
    }
  }
}
