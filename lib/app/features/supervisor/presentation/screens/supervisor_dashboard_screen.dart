import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/mosque_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';

/// لوحة المشرف — ملخص اليوم + التحضير والطلاب والتصحيحات والملاحظات
class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nextPrayer = sl<PrayerTimesService>().getNextPrayer();
    final approvedMosque = _getApprovedMosque(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAppBar(context),
                        const SizedBox(height: AppDimensions.paddingXL),
                        if (approvedMosque != null) _buildMosqueCard(context, approvedMosque),
                        const SizedBox(height: AppDimensions.paddingMD),
                        _buildNextPrayerCard(nextPrayer),
                        const SizedBox(height: AppDimensions.paddingXL),
                        _buildSectionTitle(AppStrings.todayAttendance),
                        const SizedBox(height: AppDimensions.paddingSM),
                        _buildStatsRow(),
                        const SizedBox(height: AppDimensions.paddingXL),
                        _buildSectionTitle('الإجراءات'),
                        const SizedBox(height: AppDimensions.paddingMD),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildActionCard(
                        context,
                        icon: Icons.qr_code_scanner,
                        title: 'التحضير',
                        subtitle: 'مسح QR أو إدخال رقم الطالب',
                        onTap: () => context.push('/supervisor/scan'),
                      ),
                      const SizedBox(height: AppDimensions.paddingSM),
                      _buildActionCard(
                        context,
                        icon: Icons.people,
                        title: AppStrings.students,
                        subtitle: 'قائمة طلاب المسجد',
                        onTap: () => context.push('/supervisor/students'),
                      ),
                      const SizedBox(height: AppDimensions.paddingSM),
                      _buildActionCard(
                        context,
                        icon: Icons.edit_note,
                        title: AppStrings.correctionRequest,
                        subtitle: 'طلبات التصحيح من أولياء الأمور',
                        onTap: () => context.push('/supervisor/corrections'),
                      ),
                      const SizedBox(height: AppDimensions.paddingSM),
                      _buildActionCard(
                        context,
                        icon: Icons.note_alt_outlined,
                        title: 'الملاحظات',
                        subtitle: 'ملاحظات للطلاب',
                        onTap: () => context.push('/supervisor/notes'),
                      ),
                      const SizedBox(height: AppDimensions.paddingXXL),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MosqueModel? _getApprovedMosque(BuildContext context) {
    final state = context.read<MosqueBloc>().state;
    if (state is MosqueLoaded) {
      try {
        return state.mosques.firstWhere((m) => m.status == MosqueStatus.approved);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
        ),
        const Text(
          'لوحة المشرف',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildMosqueCard(BuildContext context, MosqueModel mosque) {
    void copyAndShow(String value, String label) {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ $label'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mosque, color: Colors.white, size: 28),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: Text(
                  mosque.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          _buildCodeRow(
            context,
            label: AppStrings.mosqueCode,
            value: mosque.code,
            hint: 'لربط الأطفال (ولي الأمر)',
            onCopy: () => copyAndShow(mosque.code, AppStrings.mosqueCode),
          ),
          const SizedBox(height: 6),
          _buildCodeRow(
            context,
            label: AppStrings.inviteCode,
            value: mosque.inviteCode,
            hint: 'لدعوة المشرفين',
            onCopy: () => copyAndShow(mosque.inviteCode, AppStrings.inviteCode),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeRow(
    BuildContext context, {
    required String label,
    required String value,
    required String hint,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                hint,
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.white, size: 22),
          onPressed: onCopy,
          tooltip: AppStrings.copyCode,
        ),
      ],
    );
  }

  Widget _buildNextPrayerCard(PrayerInfo? nextPrayer) {
    final nameAr = nextPrayer?.nameAr ?? '—';
    final timeFormatted = nextPrayer?.timeFormatted ?? '—';
    final remaining = nextPrayer?.remaining;
    final remainingStr = remaining != null
        ? '${remaining.inMinutes} د'
        : '';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.nextPrayer,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '$nameAr $timeFormatted',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (remainingStr.isNotEmpty)
                  Text(
                    'بعد $remainingStr',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatChip('حضور اليوم', '0'),
        ),
        const SizedBox(width: AppDimensions.paddingSM),
        Expanded(
          child: _buildStatChip('طلاب المسجد', '—'),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMD, horizontal: AppDimensions.paddingSM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
