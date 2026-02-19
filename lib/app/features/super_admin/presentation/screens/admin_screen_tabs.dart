import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../models/mosque_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_event.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

// تبويب 1 — المساجد
// ══════════════════════════════════════════════════════════════════

class AdminMosquesTab extends StatefulWidget {
  const AdminMosquesTab();

  @override
  State<AdminMosquesTab> createState() => _AdminMosquesTabState();
}

class _AdminMosquesTabState extends State<AdminMosquesTab> {
  // null = الكل، 'pending'، 'approved'، 'rejected'
  String? _selectedStatus;

  static const _filters = [
    (key: null, label: 'الكل', color: AppColors.primary),
    (key: 'pending', label: 'قيد المراجعة', color: AppColors.warning),
    (key: 'approved', label: 'مفعّل', color: AppColors.success),
    (key: 'rejected', label: 'موقوف', color: AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<AdminBloc>().add(LoadAllMosques(
      status: _selectedStatus == null
          ? null
          : MosqueStatus.fromString(_selectedStatus!),
    ));
  }

  List<MosqueModel> _applyFilter(List<MosqueModel> mosques) {
    if (_selectedStatus == null) return mosques;
    return mosques.where((m) => m.status.value == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: BlocConsumer<AdminBloc, AdminState>(
            listener: (context, state) {
              if (state is AdminActionSuccess) {
                _showSnackBar(
                  context,
                  state.message,
                  AppColors.success,
                  Icons.check_circle_rounded,
                );
                _load();
              }
              if (state is AdminError) {
                _showSnackBar(
                  context,
                  state.message,
                  AppColors.error,
                  Icons.error_rounded,
                );
              }
            },
            builder: (context, state) {
              if (state is AdminLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is MosquesLoaded) {
                final filtered = _applyFilter(state.mosques);
                if (filtered.isEmpty) {
                  return _EmptyState(
                    icon: Icons.mosque_rounded,
                    message: 'لا توجد مساجد في هذه الفئة',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingMD),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _MosqueCard(
                      mosque: filtered[i],
                      onTap: () => _showDetails(context, filtered[i]),
                      onApprove: () => _confirmAction(
                        context,
                        title: 'تأكيد الموافقة',
                        message:
                            'هل تريد الموافقة على مسجد "${filtered[i].name}"؟',
                        onConfirm: () => context.read<MosqueBloc>().add(
                          MosqueApproveRequest(filtered[i].id),
                        ),
                      ),
                      onReject: () => _confirmAction(
                        context,
                        title: 'تأكيد الرفض',
                        message: 'هل تريد رفض طلب مسجد "${filtered[i].name}"؟',
                        isDanger: true,
                        onConfirm: () => context.read<MosqueBloc>().add(
                          MosqueRejectRequest(filtered[i].id),
                        ),
                      ),
                      onSuspend: () => _confirmAction(
                        context,
                        title: 'تأكيد التعليق',
                        message: 'هل تريد تعليق مسجد "${filtered[i].name}"؟',
                        isDanger: true,
                        onConfirm: () => context.read<AdminBloc>().add(
                          SuspendMosque(filtered[i].id),
                        ),
                      ),
                      onReactivate: () => context.read<AdminBloc>().add(
                        ReactivateMosque(filtered[i].id),
                      ),
                    ),
                  ),
                );
              }
              // MosqueBloc listener للنجاح/الخطأ
              return BlocConsumer<MosqueBloc, MosqueState>(
                listener: (context, mosqueState) {
                  if (mosqueState is MosqueError) {
                    _showSnackBar(
                      context,
                      mosqueState.message,
                      AppColors.error,
                      Icons.error_rounded,
                    );
                  }
                  if (mosqueState is MosqueLoaded) {
                    _showSnackBar(
                      context,
                      'تمت العملية بنجاح ✅',
                      AppColors.success,
                      Icons.check_circle_rounded,
                    );
                    _load();
                  }
                },
                builder: (_, __) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _load(),
                  child: const Center(child: Text('اسحب للتحديث')),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMD,
        AppDimensions.paddingSM,
        AppDimensions.paddingMD,
        AppDimensions.paddingSM,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final isSelected = _selectedStatus == f.key;
            return Padding(
              padding: const EdgeInsets.only(left: AppDimensions.spacingSM),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedStatus = f.key);
                  _load();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                    vertical: AppDimensions.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? f.color : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusRound,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: f.color.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, MosqueModel mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MosqueBottomSheet(mosque: mosque),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        title: Text(title, textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDanger ? AppColors.error : AppColors.primary,
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }
}

// بطاقة مسجد
class _MosqueCard extends StatelessWidget {
  final MosqueModel mosque;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;

  const _MosqueCard({
    required this.mosque,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onReactivate,
  });

  Color get _statusColor {
    switch (mosque.status.value) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  String get _statusLabel {
    switch (mosque.status.value) {
      case 'pending':
        return '🟡 قيد المراجعة';
      case 'approved':
        return '🟢 مفعّل';
      case 'rejected':
        return '🔴 موقوف';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // الشريط الجانبي
            Container(
              width: 5,
              height: 130,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppDimensions.radiusLG),
                  bottomRight: Radius.circular(AppDimensions.radiusLG),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mosque.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingSM,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusRound,
                            ),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (mosque.address != null &&
                        mosque.address!.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spacingXS),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: AppDimensions.spacingXS),
                          Expanded(
                            child: Text(
                              mosque.address!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spacingSM),
                    _buildActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (mosque.status.value == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text(
                AppStrings.reject,
                style: TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingSM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(
            child: FilledButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text(
                AppStrings.approve,
                style: TextStyle(fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingSM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (mosque.status.value == 'approved') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onSuspend,
          icon: const Icon(Icons.pause_circle_rounded, size: 16),
          label: const Text('تعليق المسجد'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.warning,
            side: const BorderSide(color: AppColors.warning),
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingSM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
          ),
        ),
      );
    }
    if (mosque.status.value == 'rejected') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onReactivate,
          icon: const Icon(Icons.play_circle_rounded, size: 16),
          label: const Text('إعادة التفعيل'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingSM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// Bottom Sheet تفاصيل المسجد
class _MosqueBottomSheet extends StatelessWidget {
  final MosqueModel mosque;

  const _MosqueBottomSheet({required this.mosque});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDimensions.paddingSM),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: const Text(
                    '🕌',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mosque.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (mosque.address != null)
                        Text(
                          mosque.address!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppDimensions.paddingLG),
          if (mosque.address != null)
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'العنوان',
              value: mosque.address!,
            ),
          _DetailRow(
            icon: Icons.qr_code_rounded,
            label: 'كود الدعوة',
            value: mosque.inviteCode,
          ),
          _DetailRow(
            icon: Icons.info_rounded,
            label: 'الحالة',
            value: mosque.status.value == 'approved'
                ? 'مفعّل ✅'
                : mosque.status.value == 'pending'
                ? 'قيد المراجعة 🟡'
                : 'موقوف 🔴',
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingMD,
              0,
              AppDimensions.paddingMD,
              AppDimensions.paddingLG,
            ),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showChangeImamDialog(context);
              },
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('تغيير الإمام'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  AppDimensions.buttonHeightSM,
                ),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeImamDialog(BuildContext context) {
    final controller = TextEditingController();
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        title: const Text('تغيير الإمام', textAlign: TextAlign.right),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'معرّف المستخدم الجديد',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(dialogContext);
              final newOwnerId = controller.text.trim();
              if (newOwnerId.isNotEmpty) {
                adminBloc.add(
                  ChangeImam(mosqueId: mosque.id, newOwnerId: newOwnerId),
                );
              }
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: AppDimensions.iconSM),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      dense: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// تبويب 2 — المستخدمون
// ══════════════════════════════════════════════════════════════════

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab();

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String? _selectedRole; // null = الكل
  String _searchQuery = '';
  List<Map<String, dynamic>> _allUsers = [];

  static const _roleFilters = [
    (key: null, label: 'الكل', color: AppColors.primary),
    (key: 'parent', label: 'أولياء أمور', color: AppColors.info),
    (key: 'imam', label: 'أئمة', color: AppColors.success),
    (key: 'supervisor', label: 'مشرفون', color: AppColors.warning),
    (key: 'child', label: 'أطفال', color: Color(0xFF9B59B6)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<AdminBloc>().add(LoadAllUsers(
      role: _selectedRole == null
          ? null
          : UserRole.fromString(_selectedRole!),
    ));
  }

  List<Map<String, dynamic>> _filtered() {
    return _allUsers.where((u) {
      final roleMatch = _selectedRole == null || u['role'] == _selectedRole;
      final q = _searchQuery.toLowerCase();
      final nameMatch =
          q.isEmpty ||
          (u['name'] as String? ?? '').toLowerCase().contains(q) ||
          (u['email'] as String? ?? '').toLowerCase().contains(q);
      return roleMatch && nameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: BlocConsumer<AdminBloc, AdminState>(
            listener: (context, state) {
              if (state is UsersLoaded) {
                setState(() => _allUsers = state.users);
              }
              if (state is AdminActionSuccess) {
                _showSnackBar(
                  context,
                  state.message,
                  AppColors.success,
                  Icons.check_circle_rounded,
                );
                _load();
              }
              if (state is AdminError) {
                _showSnackBar(
                  context,
                  state.message,
                  AppColors.error,
                  Icons.error_rounded,
                );
              }
            },
            builder: (context, state) {
              if (state is AdminLoading && _allUsers.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              final filtered = _filtered();
              if (filtered.isEmpty) {
                return _EmptyState(
                  icon: Icons.people_outline_rounded,
                  message: 'لا يوجد مستخدمون في هذه الفئة',
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => _load(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _UserCard(
                    user: filtered[i],
                    onChangeRole: () =>
                        _showChangeRoleDialog(context, filtered[i]),
                    onBan: () => _showBanDialog(context, filtered[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMD,
        AppDimensions.paddingSM,
        AppDimensions.paddingMD,
        0,
      ),
      child: Column(
        children: [
          TextField(
            textDirection: TextDirection.rtl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الإيميل...',
              hintTextDirection: TextDirection.rtl,
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roleFilters.map((r) {
                final isSelected = _selectedRole == r.key;
                return Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.spacingSM,
                    bottom: AppDimensions.paddingSM,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedRole = r.key);
                      _load();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMD,
                        vertical: AppDimensions.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? r.color : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusRound,
                        ),
                      ),
                      child: Text(
                        r.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, Map<String, dynamic> user) {
    String selected = user['role'] as String? ?? 'parent';
    final roleLabels = {
      'parent': 'ولي أمر',
      'imam': 'إمام',
      'supervisor': 'مشرف',
      'child': 'طفل',
    };
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          ),
          title: Text(
            'تغيير دور ${user['name'] ?? ''}',
            textAlign: TextAlign.right,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: roleLabels.entries.map((e) {
              return RadioListTile<String>(
                value: e.key,
                groupValue: selected,
                onChanged: (v) => setD(() => selected = v!),
                title: Text(e.value, textAlign: TextAlign.right),
                activeColor: AppColors.primary,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                context.read<AdminBloc>().add(UpdateUserRole(
                      userId: user['id'] as String,
                      newRole: UserRole.fromString(selected),
                    ));
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showBanDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        title: const Text('تأكيد الحظر', textAlign: TextAlign.right),
        content: Text(
          'هل تريد حظر المستخدم "${user['name']}"؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminBloc>().add(BanUser(user['id'] as String));
            },
            child: const Text('حظر'),
          ),
        ],
      ),
    );
  }
}

// بطاقة مستخدم
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onChangeRole;
  final VoidCallback onBan;

  const _UserCard({
    required this.user,
    required this.onChangeRole,
    required this.onBan,
  });

  Color get _roleColor {
    switch (user['role']) {
      case 'parent':
        return AppColors.info;
      case 'imam':
        return AppColors.success;
      case 'supervisor':
        return AppColors.warning;
      case 'child':
        return const Color(0xFF9B59B6);
      default:
        return AppColors.textHint;
    }
  }

  String get _roleLabel {
    switch (user['role']) {
      case 'parent':
        return 'ولي أمر';
      case 'imam':
        return 'إمام';
      case 'supervisor':
        return 'مشرف';
      case 'child':
        return 'طفل';
      default:
        return user['role'] ?? '';
    }
  }

  String get _initials {
    final name = user['name'] as String? ?? '?';
    return name.isNotEmpty ? name.substring(0, 1) : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Row(
          children: [
            CircleAvatar(
              radius: AppDimensions.avatarSM / 1.5,
              backgroundColor: _roleColor.withOpacity(0.15),
              child: Text(
                _initials,
                style: TextStyle(
                  color: _roleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingSM,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusRound,
                          ),
                        ),
                        child: Text(
                          _roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _roleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user['email'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onChangeRole,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spacingXS,
                            ),
                            side: BorderSide(color: _roleColor),
                            foregroundColor: _roleColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSM,
                              ),
                            ),
                          ),
                          child: const Text(
                            'تغيير الدور',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSM),
                      Flexible(
                        child: OutlinedButton(
                          onPressed: onBan,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spacingXS,
                              horizontal: AppDimensions.paddingMD,
                            ),
                            side: const BorderSide(color: AppColors.error),
                            foregroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSM,
                              ),
                            ),
                          ),
                          child: const Icon(Icons.block_rounded, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// تبويب 3 — الإحصائيات
// ══════════════════════════════════════════════════════════════════

class AdminStatsTab extends StatelessWidget {
  const AdminStatsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is SystemStatsLoaded) {
          return _buildStats(context, state.stats);
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              const Text('تعذّر تحميل الإحصائيات'),
              const SizedBox(height: AppDimensions.spacingMD),
              FilledButton(
                onPressed: () =>
                    context.read<AdminBloc>().add(const LoadSystemStats()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats(BuildContext context, Map<String, dynamic> stats) {
    final total = (stats['total_mosques'] as int?) ?? 0;
    final approved = (stats['approved_mosques'] as int?) ?? 0;
    final pending = (stats['pending_mosques'] as int?) ?? 0;
    final suspended = total - approved - pending;
    final users = (stats['total_users'] as int?) ?? 0;
    final children = (stats['total_children'] as int?) ?? 0;
    final todayAtt = (stats['today_attendance'] as int?) ?? 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          context.read<AdminBloc>().add(const LoadSystemStats()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة الترحيب
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مرحباً، سوبر أدمن 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إليك نظرة عامة على المنصة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMD),

            // الأرقام الرئيسية — GridView 2×2
            const Text(
              'الأرقام الرئيسية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppDimensions.spacingMD,
              mainAxisSpacing: AppDimensions.spacingMD,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon: Icons.mosque_rounded,
                  label: 'إجمالي المساجد',
                  value: total.toString(),
                  color: AppColors.primary,
                ),
                _StatCard(
                  icon: Icons.people_rounded,
                  label: 'إجمالي المستخدمين',
                  value: users.toString(),
                  color: AppColors.info,
                ),
                _StatCard(
                  icon: Icons.child_care_rounded,
                  label: 'إجمالي الأطفال',
                  value: children.toString(),
                  color: const Color(0xFF9B59B6),
                ),
                _StatCard(
                  icon: Icons.how_to_reg_rounded,
                  label: 'حضور اليوم',
                  value: todayAtt.toString(),
                  color: AppColors.success,
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingMD),

            // المساجد حسب الحالة
            const Text(
              'المساجد حسب الحالة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    label: 'مفعّل',
                    value: approved.toString(),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMD),
                Expanded(
                  child: _MiniStatCard(
                    label: 'معلّق',
                    value: pending.toString(),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMD),
                Expanded(
                  child: _MiniStatCard(
                    label: 'موقوف',
                    value: suspended < 0 ? '0' : suspended.toString(),
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMD),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// تبويب 4 — ملفي
// ══════════════════════════════════════════════════════════════════

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingLG),
          // Avatar
          Container(
            width: AppDimensions.avatarXL,
            height: AppDimensions.avatarXL,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: AppDimensions.iconXL,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          const Text(
            'سوبر أدمن',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'مدير النظام',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          const Divider(),

          // زر تسجيل الخروج
          ListTile(
            onTap: () => _showLogoutDialog(context),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: AppDimensions.iconSM,
              ),
            ),
            title: const Text(
              AppStrings.logout,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: AppColors.textHint,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        title: const Text('تأكيد تسجيل الخروج', textAlign: TextAlign.right),
        content: const Text(
          'هل تريد تسجيل الخروج من لوحة التحكم؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// مكوّنات مساعدة
// ══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppDimensions.iconXXL, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

void _showSnackBar(
  BuildContext context,
  String message,
  Color color,
  IconData icon,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      margin: const EdgeInsets.all(AppDimensions.paddingMD),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
// موديلات داخلية مساعدة (للـ records في Dart)
// ══════════════════════════════════════════════════════════════════

// تُستخدم داخلياً فقط — لا تصدير
class _FilterOption {
  final String? key;
  final String label;
  final Color color;
  const _FilterOption(this.key, this.label, this.color);
}
