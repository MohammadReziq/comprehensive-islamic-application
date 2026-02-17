import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// عنصر واحد في قائمة الدراور
class AppDrawerItem {
  const AppDrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

/// دراور مشترك لكل الأدوار — عنوان، قائمة روابط، تسجيل خروج
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.onLogout,
  });

  final String title;
  final String? subtitle;
  final List<AppDrawerItem> items;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final item in items)
                        ListTile(
                          leading: Icon(
                            item.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            item.onTap();
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.white70,
                    size: 24,
                  ),
                  title: Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
