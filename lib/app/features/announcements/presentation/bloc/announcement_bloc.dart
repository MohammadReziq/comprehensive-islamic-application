// lib/app/features/announcements/presentation/bloc/announcement_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/announcement_repository.dart';
import 'announcement_event.dart';
import 'announcement_state.dart';

class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  AnnouncementBloc(this._repo) : super(AnnouncementInitial()) {
    on<LoadAnnouncements>(_onLoad);
    on<CreateAnnouncement>(_onCreate);
    on<UpdateAnnouncement>(_onUpdate);
    on<DeleteAnnouncement>(_onDelete);
  }

  final AnnouncementRepository _repo;

  Future<void> _onLoad(LoadAnnouncements event, Emitter emit) async {
    emit(AnnouncementLoading());
    try {
      final list = await _repo.getForMosque(event.mosqueId);
      emit(AnnouncementsLoaded(list));
    } on AppFailure catch (f) {
      emit(AnnouncementError(f.messageAr));
    } catch (e) {
      emit(const AnnouncementError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onCreate(CreateAnnouncement event, Emitter emit) async {
    emit(AnnouncementLoading());
    try {
      await _repo.create(
        mosqueId: event.mosqueId,
        title: event.title,
        body: event.body,
        isPinned: event.isPinned,
      );
      emit(const AnnouncementActionSuccess('تم نشر الإعلان بنجاح'));
    } on AppFailure catch (f) {
      emit(AnnouncementError(f.messageAr));
    } catch (e) {
      emit(const AnnouncementError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onUpdate(UpdateAnnouncement event, Emitter emit) async {
    emit(AnnouncementLoading());
    try {
      await _repo.update(
        event.announcementId,
        title: event.title,
        body: event.body,
        isPinned: event.isPinned,
      );
      emit(const AnnouncementActionSuccess('تم تحديث الإعلان'));
    } on AppFailure catch (f) {
      emit(AnnouncementError(f.messageAr));
    } catch (e) {
      emit(const AnnouncementError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onDelete(DeleteAnnouncement event, Emitter emit) async {
    emit(AnnouncementLoading());
    try {
      await _repo.delete(event.announcementId);
      emit(const AnnouncementActionSuccess('تم حذف الإعلان'));
    } on AppFailure catch (f) {
      emit(AnnouncementError(f.messageAr));
    } catch (e) {
      emit(const AnnouncementError('حدث خطأ غير متوقع'));
    }
  }
}
