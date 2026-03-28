import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_responsive.dart';

/// عنوان وnsubtitle مشتركان لشاشتي Login وRegister.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: r.textXXL,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 700.ms)
            .slideY(begin: -0.3, curve: Curves.easeOut),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: r.textSM,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
      ],
    );
  }
}
