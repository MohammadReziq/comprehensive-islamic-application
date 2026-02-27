import 'package:flutter/material.dart';
import '../../../../core/constants/app_responsive.dart';

/// بطاقة اختيار الدور (ولي أمر / إمام) في نموذج التسجيل.
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.r,
  });

  final Widget emoji;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final AppResponsive r;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(r.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(r.radiusMD),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.18),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            emoji,
            SizedBox(height: r.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: r.textSM,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
