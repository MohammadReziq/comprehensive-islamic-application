import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/competition_model.dart';

/// مشاركة نتائج المسابقة — نسخ أو مشاركة عبر التطبيقات
class CompetitionResultsSharer {
  /// بناء نص النتائج
  static String buildResultsText({
    required String competitionName,
    required String mosqueName,
    required DateTime startDate,
    required DateTime endDate,
    required List<LeaderboardEntry> entries,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('╔══════════════════════════════════╗');
    buffer.writeln('║  نتائج: $competitionName');
    buffer.writeln('║  مسجد: $mosqueName');
    buffer.writeln(
        '║  من ${_formatDate(startDate)} إلى ${_formatDate(endDate)}');
    buffer.writeln('╚══════════════════════════════════╝');
    buffer.writeln('');

    final topCount = min(entries.length, 10);
    for (int i = 0; i < topCount; i++) {
      final e = entries[i];
      final medal = switch (i) {
        0 => '🥇',
        1 => '🥈',
        2 => '🥉',
        _ => '${i + 1}.',
      };
      buffer.writeln('$medal ${e.childName} — ${e.totalPoints} نقطة');
    }

    if (entries.length > 10) {
      buffer.writeln('... و ${entries.length - 10} مشاركين آخرين');
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 عدد المشاركين: ${entries.length}');

    if (entries.isNotEmpty) {
      final avg =
          entries.map((e) => e.totalPoints).reduce((a, b) => a + b) ~/
              entries.length;
      buffer.writeln('📈 متوسط النقاط: $avg نقطة');
    }

    buffer.writeln('');
    buffer.writeln('عبر تطبيق صلاتي حياتي 🕌');

    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// نسخ للحافظة
  static Future<void> copyResults({
    required String text,
    required BuildContext context,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ النتائج ✅'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// مشاركة عبر التطبيقات
  static Future<void> shareResults({required String text}) async {
    await Share.share(text, subject: 'نتائج مسابقة صلاتي حياتي');
  }
}
