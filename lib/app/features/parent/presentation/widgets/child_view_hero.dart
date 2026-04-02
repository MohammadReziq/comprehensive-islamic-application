import 'package:flutter/material.dart';
import '../../../../models/child_model.dart';

/// قسم Hero لشاشة الابن — الأفاتار + الاسم + المستوى
class ChildViewHero extends StatelessWidget {
  final ChildModel child;

  const ChildViewHero({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final level = (child.totalPoints ~/ 100) + 1;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5),
                ),
                child: Center(
                  child: Text(
                    child.name.isNotEmpty ? child.name[0] : '؟',
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                child.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'المستوى $level',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFD54F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
