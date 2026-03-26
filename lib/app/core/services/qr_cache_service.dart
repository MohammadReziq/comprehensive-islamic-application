import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تخزين بيانات QR محلياً — حتى يعمل بدون إنترنت
class QrCacheService {
  static const _prefix = 'child_qr_cache_';

  /// حفظ بيانات QR للطفل
  static Future<void> cacheChildData({
    required String childId,
    required String childName,
    required String qrCode,
    Map<String, int>? localNumbers, // {mosqueId: localNumber}
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$childId',
      jsonEncode({
        'id': childId,
        'name': childName,
        'qr_code': qrCode,
        'local_numbers': localNumbers ?? {},
        'cached_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// جلب بيانات QR المحفوظة
  static Future<Map<String, dynamic>?> getCachedData(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$childId');
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// حذف cache لطفل محدد
  static Future<void> clearCache(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$childId');
  }

  /// حذف كل الـ cache
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
