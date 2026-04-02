import 'package:flutter/material.dart';
import '../../../../models/mosque_model.dart';
import '../../../../models/other_models.dart';

/// BottomSheet قائمة المشرفين — مع إمكانية الإضافة والإزالة.
class ImamSupervisorsSheet extends StatelessWidget {
  const ImamSupervisorsSheet({
    super.key,
    required this.mosque,
    required this.supervisors,
    required this.isLoading,
    required this.removingUserId,
    required this.onRemove,
    required this.onAddNew,
  });

  final MosqueModel mosque;
  final List<MosqueMemberModel>? supervisors;
  final bool isLoading;
  final String? removingUserId;
  final void Function(MosqueMemberModel) onRemove;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'المشرفون',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
              color: Colors.white70, strokeWidth: 2),
        ),
      );
    }
    final list = supervisors ?? [];
    return Column(
      children: [
        // ─── زر إضافة مشرف ───
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            onPressed: onAddNew,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text(
              'إضافة مشرف جديد',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D7DD2),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        // ─── قائمة المشرفين ───
        if (list.isEmpty)
          _SheetEmpty('لا يوجد مشرفون بعد. شارك كود الدعوة لدعوتهم.')
        else
          ...list.map((m) {
            final isRemoving = removingUserId == m.userId;
            return _MemberRow(
              member: m,
              isRemoving: isRemoving,
              onRemove: () => onRemove(m),
            );
          }),
      ],
    );
  }
}

// ── Join Requests Sheet ──────────────────────────────────────────────────

/// BottomSheet طلبات الانضمام.
class ImamJoinRequestsSheet extends StatelessWidget {
  const ImamJoinRequestsSheet({
    super.key,
    required this.requests,
    required this.isLoading,
    required this.processingRequestId,
    required this.onApprove,
    required this.onReject,
  });

  final List<MosqueJoinRequestModel>? requests;
  final bool isLoading;
  final String? processingRequestId;
  final void Function(MosqueJoinRequestModel) onApprove;
  final void Function(MosqueJoinRequestModel) onReject;

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'طلبات الانضمام',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
              color: Colors.white70, strokeWidth: 2),
        ),
      );
    }
    final list = requests ?? [];
    if (list.isEmpty) {
      return const _SheetEmpty('لا توجد طلبات انضمام جديدة.');
    }
    return Column(
      children: list.map((r) {
        final isProcessing = processingRequestId == r.id;
        return _RequestRow(
          request: r,
          isProcessing: isProcessing,
          onApprove: () => onApprove(r),
          onReject: () => onReject(r),
        );
      }).toList(),
    );
  }
}

// ── Shared internal widgets ──────────────────────────────────────────────

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2137),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 6),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetEmpty extends StatelessWidget {
  const _SheetEmpty(this.msg);
  final String msg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isRemoving,
    required this.onRemove,
  });

  final MosqueMemberModel member;
  final bool isRemoving;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            _AvatarIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.userName ?? member.userEmail ?? 'مشرف',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  if (member.userEmail != null &&
                      member.userEmail!.isNotEmpty)
                    Text(
                      member.userEmail!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.55)),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: isRemoving ? null : onRemove,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isRemoving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white70),
                      )
                    : const Icon(Icons.person_remove_rounded,
                        color: Colors.white54, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  final MosqueJoinRequestModel request;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            _AvatarIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.userName ?? request.userEmail ?? 'مستخدم',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  if (request.userEmail != null &&
                      request.userEmail!.isNotEmpty)
                    Text(
                      request.userEmail!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.55)),
                    ),
                ],
              ),
            ),
            if (isProcessing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white70),
              )
            else ...[
              _ActionIcon(
                color: const Color(0xFF4CAF50),
                icon: Icons.check_rounded,
                iconColor: const Color(0xFF69F0AE),
                onTap: onApprove,
              ),
              const SizedBox(width: 8),
              _ActionIcon(
                color: const Color(0xFFE53935),
                icon: Icons.close_rounded,
                iconColor: const Color(0xFFFF5252),
                onTap: onReject,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white60, size: 22),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
