import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';

/// ألوان كل دور
const roleColors = <UserRole, Color>{
  UserRole.parent: Color(0xFF5C6BC0),
  UserRole.imam: Color(0xFF2E8B57),
  UserRole.supervisor: Color(0xFF1B5E8A),
  UserRole.superAdmin: Color(0xFF6A1B9A),
  UserRole.child: Color(0xFF00897B),
};

/// Hero Section — Avatar + اسم + دور
class ProfileHeroSection extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final UserRole role;

  const ProfileHeroSection({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = roleColors[role] ?? const Color(0xFF2E8B57);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D2137),
            const Color(0xFF1B5E8A),
            accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : '؟',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  role.nameAr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
