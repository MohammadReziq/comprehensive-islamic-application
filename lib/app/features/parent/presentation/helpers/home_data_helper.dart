import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/smart_location_manager.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../../models/competition_model.dart';
import '../../../announcements/data/repositories/announcement_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../competitions/data/repositories/competition_repository.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';
import '../../../notes/data/repositories/notes_repository.dart';
import '../../data/repositories/child_repository.dart';

class HomeDataHelper extends ChangeNotifier {
  List<AttendanceModel> todayAttendance = [];
  bool loadingAttendance = false;

  double? prayerLat;
  double? prayerLng;
  bool prayerLoadError = false;
  bool loadingPrayer = true;

  /// حالة إذن الموقع — يستخدمها الـ UI لعرض البانر المناسب
  LocationPermissionStatus permissionStatus = LocationPermissionStatus.unknown;

  CompetitionStatus competitionStatus = CompetitionStatus.noCompetition;
  CompetitionModel? competition;
  String? competitionMosqueName;

  int unreadCount = 0;
  int announcementsUnreadCount = 0;

  bool _realtimeSubscribed = false;
  List<ChildModel> _latestChildren = [];
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    stopRealtime();
    super.dispose();
  }

  void disposeHelper() {
    if (!_isDisposed) dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void stopRealtime() {
    sl<RealtimeService>().unsubscribeAttendance();
    sl<RealtimeService>().unsubscribeNotes();
  }

  Future<void> loadAll() async {
    loadPrayerTimesWithLocation();
    loadCompetitionStatus();
    loadUnreadCount();
  }

  // ── مواقيت الصلاة — النسخة الذكية ─────────────────────────

  Future<void> loadPrayerTimesWithLocation() async {
    loadingPrayer = true;
    prayerLoadError = false;
    notifyListeners();

    // الخطوة 1: حاول تحميل المواقيت من الكاش فوراً
    final cachedOk = await _tryLoadFromPrayerCache();
    if (cachedOk) {
      loadingPrayer = false;
      notifyListeners();
    }

    // الخطوة 2: Smart Location (فوري من الكاش أو GPS إن لزم)
    await SmartLocationManager.getLocationSmart(
      onLocationReady: (lat, lng) {
        prayerLat = lat;
        prayerLng = lng;
        loadingPrayer = false;
        notifyListeners();
        _loadAndCacheTimings(lat, lng);
      },
      onLocationUpdated: (lat, lng) {
        // الموقع تغيّر بشكل ملحوظ بعد التحديث الخلفي
        prayerLat = lat;
        prayerLng = lng;
        notifyListeners();
        _loadAndCacheTimings(lat, lng);
      },
      onPermissionStatus: (status) {
        permissionStatus = status;
        if (status != LocationPermissionStatus.granted && !cachedOk) {
          loadingPrayer = false;
        }
        notifyListeners();
      },
    );
  }

  /// يحاول تحميل المواقيت من كاش SharedPreferences
  Future<bool> _tryLoadFromPrayerCache() async {
    try {
      final saved = await SmartLocationManager.getSavedLocation();
      if (saved.lat == null || saved.lng == null) return false;

      final ok =
          await sl<PrayerTimesService>().loadTimingsFor(saved.lat!, saved.lng!);
      if (ok) {
        prayerLat = saved.lat;
        prayerLng = saved.lng;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// يحمّل المواقيت من API ويحفظها في الكاش
  Future<void> _loadAndCacheTimings(double lat, double lng) async {
    final ok = await sl<PrayerTimesService>().loadTimingsFor(lat, lng);
    prayerLoadError = !ok;
    notifyListeners();
  }

  /// إعادة طلب إذن الموقع (يُستدعى من UI عند ضغط المستخدم)
  Future<void> requestLocationPermission() async {
    loadingPrayer = true;
    notifyListeners();

    await SmartLocationManager.getLocationSmart(
      onLocationReady: (lat, lng) {
        prayerLat = lat;
        prayerLng = lng;
        loadingPrayer = false;
        notifyListeners();
        _loadAndCacheTimings(lat, lng);
      },
      onPermissionStatus: (status) {
        permissionStatus = status;
        loadingPrayer = false;
        notifyListeners();
      },
    );
  }

  // ── المسابقات ──────────────────────────────────────────────

  Future<void> loadCompetitionStatus() async {
    try {
      final children = await sl<ChildRepository>().getMyChildren();
      final mosqueIds = <String>{};
      for (final c in children) {
        final ids = await sl<ChildRepository>().getChildMosqueIds(c.id);
        mosqueIds.addAll(ids);
      }
      if (mosqueIds.isEmpty) return;
      for (final mosqueId in mosqueIds) {
        final result =
            await sl<CompetitionRepository>().getCompetitionStatus(mosqueId);
        if (result.status != CompetitionStatus.noCompetition) {
          String? mosqueName;
          try {
            final mosques =
                await sl<MosqueRepository>().getMosquesByIds([mosqueId]);
            if (mosques.isNotEmpty) mosqueName = mosques.first.name;
          } catch (_) {}

          competitionStatus = result.status;
          competition = result.competition;
          competitionMosqueName = mosqueName;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}
  }

  // ── عدد غير المقروء ─────────────────────────────────────────

  Future<void> loadUnreadCount() async {
    try {
      final children = await sl<ChildRepository>().getMyChildren();
      final childIds = children.map((c) => c.id).toList();
      final notes =
          await sl<NotesRepository>().getNotesForMyChildren(childIds);
      final unreadNotes = notes.where((n) => !n.isRead).length;

      final mosqueIds = <String>{};
      for (final c in children) {
        final ids = await sl<ChildRepository>().getChildMosqueIds(c.id);
        mosqueIds.addAll(ids);
      }
      int unreadAnn = 0;
      if (mosqueIds.isNotEmpty) {
        final user = await sl<AuthRepository>().getCurrentUserProfile();
        if (user != null) {
          final anns = await sl<AnnouncementRepository>()
              .getForParent(mosqueIds.toList());
          final readIds =
              await sl<AnnouncementRepository>().getReadIds(user.id);
          unreadAnn = anns.where((a) => !readIds.contains(a.id)).length;
        }
      }

      unreadCount = unreadNotes;
      announcementsUnreadCount = unreadAnn;
      notifyListeners();
    } catch (_) {}
  }

  // ── Realtime ───────────────────────────────────────────────

  void startRealtime(List<String> childIds) {
    if (_realtimeSubscribed) return;
    _realtimeSubscribed = true;
    sl<RealtimeService>().subscribeAttendanceForChildIds(childIds, (_) {
      loadTodayAttendance(_latestChildren);
    });
    sl<RealtimeService>().subscribeNotesForChildren(childIds, (_) {
      loadUnreadCount();
    });
  }

  Future<void> loadTodayAttendance(List<ChildModel> children) async {
    _latestChildren = children;
    if (children.isEmpty) return;

    loadingAttendance = true;
    notifyListeners();

    try {
      final list = await sl<ChildRepository>()
          .getAttendanceForMyChildren(DateTime.now());
      todayAttendance = list;
    } catch (_) {}

    loadingAttendance = false;
    notifyListeners();
  }

  void refreshChildren(List<ChildModel> children) {
    _latestChildren = children;
    if (children.isNotEmpty) {
      startRealtime(children.map((c) => c.id).toList());
    }
    loadTodayAttendance(children);
  }
}
