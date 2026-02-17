import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

/// خدمة التحديث المباشر — الاشتراك في تغييرات الجداول (حضور، مساجد، إلخ)
class RealtimeService {
  RealtimeChannel? _attendanceChannel;
  RealtimeChannel? _mosquesChannel;
  RealtimeChannel? _mosqueChildrenChannel;

  /// الاشتراك في تغييرات الحضور لأطفال معيّنين (لولي الأمر).
  /// عند أي INSERT/UPDATE/DELETE على attendance لـ child_id من القائمة → يستدعى onEvent.
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

  /// الاشتراك في تغييرات جدول المساجد (لبوابة المسجد / لوحة الإمام).
  /// عند أي تغيير على mosques → يستدعى onEvent (مثلاً لإعادة جلب المساجد بعد موافقة الأدمن).
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

  /// الاشتراك في تغييرات ربط الأطفال بالمسجد (mosque_children).
  /// عند إضافة/حذف/تعديل ربط طفل بمسجد معيّن → يستدعى onEvent (لتحديث عدد "طلاب المسجد" فوراً).
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

  /// إلغاء اشتراك الحضور
  void unsubscribeAttendance() {
    _attendanceChannel?.unsubscribe();
    _attendanceChannel = null;
  }

  /// إلغاء اشتراك المساجد
  void unsubscribeMosques() {
    _mosquesChannel?.unsubscribe();
    _mosquesChannel = null;
  }

  /// إلغاء اشتراك mosque_children
  void unsubscribeMosqueChildren() {
    _mosqueChildrenChannel?.unsubscribe();
    _mosqueChildrenChannel = null;
  }

  /// إلغاء كل الاشتراكات
  void dispose() {
    unsubscribeAttendance();
    unsubscribeMosques();
    unsubscribeMosqueChildren();
  }
}
