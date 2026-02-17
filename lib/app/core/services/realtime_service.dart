import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

/// خدمة التحديث المباشر — الاشتراك في تغييرات الجداول (حضور، مساجد، إلخ)
class RealtimeService {
  RealtimeChannel? _attendanceChannel;
  RealtimeChannel? _mosquesChannel;

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

  /// إلغاء كل الاشتراكات
  void dispose() {
    unsubscribeAttendance();
    unsubscribeMosques();
  }
}
