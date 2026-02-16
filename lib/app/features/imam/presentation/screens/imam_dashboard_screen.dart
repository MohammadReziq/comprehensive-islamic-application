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
import '../../../../models/other_models.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_event.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';

/// لوحة مدير المسجد (الإمام) — صفحة مخصصة للإمام: إدارة المشرفين، الأكواد، والإجراءات
class ImamDashboardScreen extends StatefulWidget {
  const ImamDashboardScreen({super.key});

  @override
  State<ImamDashboardScreen> createState() => _ImamDashboardScreenState();
}

class _ImamDashboardScreenState extends State<ImamDashboardScreen> {
  List<MosqueMemberModel>? _supervisors;
  bool _loadingSupervisors = false;
  List<MosqueJoinRequestModel>? _pendingRequests;
  bool _loadingPendingRequests = false;
  String? _removingUserId;
  String? _processingRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<MosqueBloc>().state;
      if (state is! MosqueLoaded || state.mosques.isEmpty) {
        context.read<MosqueBloc>().add(const MosqueLoadMyMosques());
      }
    });
  }

  void _loadSupervisors(String mosqueId) async {
    setState(() => _loadingSupervisors = true);
    try {
      final list = await sl<MosqueRepository>().getMosqueSupervisors(mosqueId);
      if (mounted) setState(() {
        _supervisors = list;
        _loadingSupervisors = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _supervisors = [];
        _loadingSupervisors = false;
      });
    }
  }

  void _loadPendingRequests(String mosqueId) async {
    setState(() => _loadingPendingRequests = true);
    try {
      final list = await sl<MosqueRepository>().getPendingJoinRequests(mosqueId);
      if (mounted) setState(() {
        _pendingRequests = list;
        _loadingPendingRequests = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _pendingRequests = [];
        _loadingPendingRequests = false;
      });
    }
  }

  Future<void> _removeSupervisor(MosqueModel mosque, MosqueMemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.removeSupervisor),
        content: Text(
          'هل تريد إزالة "${member.userName ?? member.userEmail ?? 'المشرف'}" من مسجد ${mosque.name}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _removingUserId = member.userId);
    try {
      await sl<MosqueRepository>().removeMosqueMember(mosque.id, member.userId);
      if (mounted) {
        setState(() {
          _supervisors = _supervisors?.where((m) => m.userId != member.userId).toList() ?? [];
          _removingUserId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إزالة المشرف'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _removingUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = sl<PrayerTimesService>().getNextPrayer();
    return BlocBuilder<MosqueBloc, MosqueState>(
      builder: (context, state) {
        MosqueModel? mosque;
        if (state is MosqueLoaded) {
          try {
            mosque = state.mosques.firstWhere((m) => m.status == MosqueStatus.approved);
          } catch (_) {}
        }
        if (mosque != null && _supervisors == null && !_loadingSupervisors) {
          _loadingSupervisors = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadSupervisors(mosque!.id);
          });
        }
        if (mosque != null && _pendingRequests == null && !_loadingPendingRequests) {
          _loadingPendingRequests = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadPendingRequests(mosque!.id);
          });
        }

        final initialDataReady = mosque != null &&
            _supervisors != null &&
            _pendingRequests != null;

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
                child: !initialDataReady
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'جاري التحميل...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(AppDimensions.paddingLG),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAppBar(context),
                                  const SizedBox(height: AppDimensions.paddingXL),
                                  _buildMosqueCard(context, mosque),
                                  const SizedBox(height: AppDimensions.paddingXL),
                                  _buildSectionTitle('طلبات الانضمام'),
                                  const SizedBox(height: AppDimensions.paddingSM),
                                  _buildPendingJoinRequestsContent(context, mosque),
                                  const SizedBox(height: AppDimensions.paddingXL),
                                  _buildSectionTitle(AppStrings.supervisors),
                                  const SizedBox(height: AppDimensions.paddingSM),
                                  _buildSupervisorsContent(context, mosque),
                                  const SizedBox(height: AppDimensions.paddingXL),
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
      },
    );
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
          'لوحة مدير المسجد',
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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

  Widget _buildPendingJoinRequestsContent(BuildContext context, MosqueModel mosque) {
    if (_loadingPendingRequests) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLG),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
        ),
      );
    }
    final list = _pendingRequests ?? [];
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        child: Text(
          'لا توجد طلبات انضمام جديدة.',
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
        ),
      );
    }
    return Column(
      children: list.map((r) {
        final isProcessing = _processingRequestId == r.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
              vertical: AppDimensions.paddingSM,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Row(
              children: [
                Icon(Icons.person_add, color: Colors.white70, size: 22),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.userName ?? r.userEmail ?? 'مستخدم طلب الانضمام',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (r.userEmail != null && r.userEmail!.isNotEmpty)
                        Text(
                          r.userEmail!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isProcessing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 26),
                    onPressed: () => _approveJoinRequest(mosque, r),
                    tooltip: AppStrings.approve,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 24),
                    onPressed: () => _rejectJoinRequest(mosque, r),
                    tooltip: AppStrings.reject,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _approveJoinRequest(MosqueModel mosque, MosqueJoinRequestModel request) async {
    setState(() => _processingRequestId = request.id);
    try {
      await sl<MosqueRepository>().approveJoinRequest(request.id);
      if (mounted) {
        setState(() {
          _pendingRequests = _pendingRequests?.where((r) => r.id != request.id).toList() ?? [];
          _processingRequestId = null;
          _supervisors = null;
          _loadingSupervisors = false;
        });
        _loadSupervisors(mosque.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت الموافقة على طلب الانضمام'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingRequestId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectJoinRequest(MosqueModel mosque, MosqueJoinRequestModel request) async {
    setState(() => _processingRequestId = request.id);
    try {
      await sl<MosqueRepository>().rejectJoinRequest(request.id);
      if (mounted) {
        setState(() {
          _pendingRequests = _pendingRequests?.where((r) => r.id != request.id).toList() ?? [];
          _processingRequestId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض طلب الانضمام'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingRequestId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSupervisorsContent(BuildContext context, MosqueModel mosque) {
    if (_loadingSupervisors) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLG),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
        ),
      );
    }
    final list = _supervisors ?? [];
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        child: Text(
          'لا يوجد مشرفون بعد. شارك كود الدعوة لدعوتهم.',
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
        ),
      );
    }
    return Column(
      children: list.map((m) {
        final isRemoving = _removingUserId == m.userId;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
              vertical: AppDimensions.paddingSM,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.white70, size: 22),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.userName ?? m.userEmail ?? 'مشرف',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (m.userEmail != null && m.userEmail!.isNotEmpty)
                        Text(
                          m.userEmail!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: isRemoving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                        )
                      : const Icon(Icons.person_remove, color: Colors.white70, size: 24),
                  onPressed: isRemoving ? null : () => _removeSupervisor(mosque, m),
                  tooltip: AppStrings.removeSupervisor,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextPrayerCard(dynamic nextPrayer) {
    final nameAr = nextPrayer?.nameAr ?? '—';
    final timeFormatted = nextPrayer?.timeFormatted ?? '—';
    final remaining = nextPrayer?.remaining;
    final remainingStr = remaining != null ? '${remaining.inMinutes} د' : '';

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
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
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
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
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
        Expanded(child: _buildStatChip('حضور اليوم', '0')),
        const SizedBox(width: AppDimensions.paddingSM),
        Expanded(child: _buildStatChip('طلاب المسجد', '—')),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.paddingMD,
        horizontal: AppDimensions.paddingSM,
      ),
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
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
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
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
