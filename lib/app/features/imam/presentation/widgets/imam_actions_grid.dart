import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/shared_dashboard_widgets.dart';
import '../../../../models/mosque_model.dart';

/// شبكة الإجراءات الـ 11 في لوحة تحكم الإمام.
class ImamActionsGrid extends StatelessWidget {
  const ImamActionsGrid({
    super.key,
    required this.mosque,
    required this.nextPrayer,
    required this.onSupervisorsTap,
    required this.onStatsRefresh,
    required this.router,
  });

  final MosqueModel mosque;
  final dynamic nextPrayer;
  final VoidCallback onSupervisorsTap;
  final VoidCallback onStatsRefresh;

  /// دالة navigation (context.push) مُمررة من الشاشة الأب.
  final void Function(String route, {Object? extra}) router;

  List<DashboardActionItem> _buildActions() {
    return [
      DashboardActionItem(
        icon: Icons.people_outline_rounded,
        title: 'المشرفون',
        color: const Color(0xFF5C8BFF),
        onTap: onSupervisorsTap,
      ),
      DashboardActionItem(
        icon: Icons.qr_code_scanner_rounded,
        title: 'التحضير',
        color: const Color(0xFF4CAF50),
        onTap: () {
          router('/supervisor/scan');
          onStatsRefresh();
        },
      ),
      DashboardActionItem(
        icon: Icons.people_rounded,
        title: AppStrings.students,
        color: const Color(0xFFFF7043),
        onTap: () {
          router('/supervisor/students');
          onStatsRefresh();
        },
      ),
      DashboardActionItem(
        icon: Icons.edit_note_rounded,
        title: 'طلب تصحيح',
        color: const Color(0xFF9C27B0),
        onTap: () => router('/imam/corrections/${mosque.id}'),
      ),
      DashboardActionItem(
        icon: Icons.note_alt_outlined,
        title: 'الملاحظات',
        color: const Color(0xFF00BCD4),
        onTap: () => router('/supervisor/notes/send/${mosque.id}'),
      ),
      DashboardActionItem(
        icon: Icons.campaign_rounded,
        title: 'الإعلانات',
        color: const Color(0xFF2E8B57),
        onTap: () => router('/imam/announcements/${mosque.id}'),
      ),
      DashboardActionItem(
        icon: Icons.emoji_events_rounded,
        title: 'المسابقات',
        color: const Color(0xFFFFB300),
        onTap: () => router('/imam/competitions/${mosque.id}'),
      ),
      DashboardActionItem(
        icon: Icons.star_rounded,
        title: 'نقاط الصلاة',
        color: const Color(0xFFE91E63),
        onTap: () => router(
          '/imam/mosque/${mosque.id}/prayer-points',
          extra: mosque.name,
        ),
      ),
      DashboardActionItem(
        icon: Icons.settings_rounded,
        title: 'إعدادات المسجد',
        color: const Color(0xFF607D8B),
        onTap: () => router(
          '/imam/mosque/${mosque.id}/settings',
          extra: mosque,
        ),
      ),
      DashboardActionItem(
        icon: Icons.bar_chart_rounded,
        title: 'تقرير الحضور',
        color: const Color(0xFF26A69A),
        onTap: () =>
            router('/imam/mosque/${mosque.id}/attendance-report'),
      ),
      DashboardActionItem(
        icon: Icons.workspace_premium_rounded,
        title: 'أداء المشرفين',
        color: const Color(0xFF7E57C2),
        onTap: () =>
            router('/imam/mosque/${mosque.id}/supervisors-performance'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 14),
          child: Text(
            'الإجراءات',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
              letterSpacing: -0.2,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, i) => DashboardActionTile(item: actions[i]),
        ),
      ],
    );
  }
}
