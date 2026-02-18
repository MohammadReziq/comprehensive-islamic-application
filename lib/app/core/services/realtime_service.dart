import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

/// خدمة التحديث المباشر — الاشتراك في تغييرات الجداول (حضور، مساجد، إلخ)
class RealtimeService {
  RealtimeChannel? _attendanceChannel;
  RealtimeChannel? _mosquesChannel;
  RealtimeChannel? _mosqueChildrenChannel;
  RealtimeChannel? _correctionsChannel;
  RealtimeChannel? _notesChannel;
  RealtimeChannel? _announcementsChannel;

  /// الاشتراك في تغييرات الحضور لأطفال معيّنين (لولي الأمر).
  void subscribeAttendanceForChildIds(
    List<String> childIds,
    void Function(PostgresChangePayload payload) onEvent,
  ) {
    if (childIds.isEmpty) return;
    _attendanceChannel?.unsubscribe();

    final channelName = 'attendance-${DateTime.now().millisecondsSinceEpoch}';
    final filter = childIds.length == 1
        ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'child_id',
            value: childIds.single,
          )
        : (childIds.length <= 100
            ? PostgresChangeFilter(
                type: PostgresChangeFilterType.inFilter,
                column: 'child_id',
                value: childIds,
              )
            : null);

    _attendanceChannel = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          filter: filter,
          callback: onEvent,
        )
        .subscribe();
  }

  /// الاشتراك في تغييرات جدول المساجد
  void subscribeMosques(void Function(PostgresChangePayload payload) onEvent) {
    _mosquesChannel?.unsubscribe();

    final channelName = 'mosques-${DateTime.now().millisecondsSinceEpoch}';
    _mosquesChannel = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mosques',
          callback: onEvent,
        )
        .subscribe();
  }

  /// الاشتراك في تغييرات ربط الأطفال بالمسجد
  void subscribeMosqueChildren(
    String mosqueId,
    void Function(PostgresChangePayload payload) onEvent,
  ) {
    _mosqueChildrenChannel?.unsubscribe();

    final channelName =
        'mosque-children-${DateTime.now().millisecondsSinceEpoch}';
    _mosqueChildrenChannel = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mosque_children',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'mosque_id',
            value: mosqueId,
          ),
          callback: onEvent,
        )
        .subscribe();
  }

  // ─── قنوات جديدة ───

  /// الاشتراك في طلبات التصحيح لمسجد (للإمام/المشرف)
  void subscribeCorrectionRequests(
    String mosqueId,
    void Function(PostgresChangePayload payload) onEvent,
  ) {
    _correctionsChannel?.unsubscribe();

    final channelName =
        'corrections-${DateTime.now().millisecondsSinceEpoch}';
    _correctionsChannel = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'correction_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'mosque_id',
            value: mosqueId,
          ),
          callback: onEvent,
        )
        .subscribe();
  }

  /// الاشتراك في الملاحظات لأطفال معينين (لولي الأمر)
  void subscribeNotesForChildren(
    List<String> childIds,
    void Function(PostgresChangePayload payload) onEvent,
  ) {
    if (childIds.isEmpty) return;
    _notesChannel?.unsubscribe();

    final channelName = 'notes-${DateTime.now().millisecondsSinceEpoch}';
    final filter = childIds.length == 1
        ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'child_id',
            value: childIds.single,
          )
        : (childIds.length <= 100
            ? PostgresChangeFilter(
                type: PostgresChangeFilterType.inFilter,
                column: 'child_id',
                value: childIds,
              )
            : null);

    _notesChannel = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          filter: filter,
          callback: onEvent,
        )
        .subscribe();
  }

  /// الاشتراك في إعلانات مسجد
  void subscribeAnnouncements(
    String mosqueId,
    void Function(PostgresChangePayload payload) onEvent,
  ) {
    _announcementsChannel?.unsubscribe();

    final channelName =
        'announcements-${DateTime.now().millisecondsSinceEpoch}';
    _announcementsChannel = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'mosque_id',
            value: mosqueId,
          ),
          callback: onEvent,
        )
        .subscribe();
  }

  // ─── إلغاء الاشتراكات ───

  void unsubscribeAttendance() {
    _attendanceChannel?.unsubscribe();
    _attendanceChannel = null;
  }

  void unsubscribeMosques() {
    _mosquesChannel?.unsubscribe();
    _mosquesChannel = null;
  }

  void unsubscribeMosqueChildren() {
    _mosqueChildrenChannel?.unsubscribe();
    _mosqueChildrenChannel = null;
  }

  void unsubscribeCorrections() {
    _correctionsChannel?.unsubscribe();
    _correctionsChannel = null;
  }

  void unsubscribeNotes() {
    _notesChannel?.unsubscribe();
    _notesChannel = null;
  }

  void unsubscribeAnnouncements() {
    _announcementsChannel?.unsubscribe();
    _announcementsChannel = null;
  }

  /// إلغاء كل الاشتراكات
  void dispose() {
    unsubscribeAttendance();
    unsubscribeMosques();
    unsubscribeMosqueChildren();
    unsubscribeCorrections();
    unsubscribeNotes();
    unsubscribeAnnouncements();
  }
}

