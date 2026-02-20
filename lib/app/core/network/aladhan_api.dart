// عميل Aladhan API — مواقيت الصلاة (مجاني، لا مفتاح مطلوب)

import 'package:dio/dio.dart';
import '../constants/app_enums.dart';

const _baseUrl = 'https://api.aladhan.com/v1';
/// طريقة الحساب: 3 = Muslim World League (مناسبة للأردن والمنطقة)
const _method = 3;

/// أوقات الصلوات الخمس لليوم (من API)
Map<Prayer, DateTime>? _parseTimings(Map<String, dynamic>? data, DateTime date) {
  if (data == null) return null;
  final timings = data['timings'] as Map<String, dynamic>?;
  if (timings == null) return null;

  DateTime? parse(String key) {
    final value = timings[key] as String?;
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].split(' ').first);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  final fajr = parse('Fajr');
  final dhuhr = parse('Dhuhr');
  final asr = parse('Asr');
  final maghrib = parse('Maghrib');
  final isha = parse('Isha');
  if (fajr == null || dhuhr == null || asr == null || maghrib == null || isha == null) return null;

  return {
    Prayer.fajr: fajr,
    Prayer.dhuhr: dhuhr,
    Prayer.asr: asr,
    Prayer.maghrib: maghrib,
    Prayer.isha: isha,
  };
}

final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));

/// جلب أوقات الصلاة ليوم معين حسب الإحداثيات
/// [lat], [lng]: خط العرض والطول (مثلاً موقع المسجد أو المستخدم)
/// [date]: التاريخ المطلوب؛ إن لم يُمرَّر يُستخدم اليوم
Future<Map<Prayer, DateTime>?> getTimings({
  required double lat,
  required double lng,
  DateTime? date,
}) async {
  final d = date ?? DateTime.now();
  final dateStr = '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  final url = '$_baseUrl/timings/$dateStr';
  try {
    final response = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: {'latitude': lat, 'longitude': lng, 'method': _method},
    );
    if (response.data == null) return null;
    final data = response.data!['data'] as Map<String, dynamic>?;
    return _parseTimings(data, d);
  } catch (_) {
    return null;
  }
}
