import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';

class HomeCredentialsDialog extends StatelessWidget {
  final String email;
  final String password;

  const HomeCredentialsDialog({
    super.key,
    required this.email,
    required this.password,
  });

  static void show(BuildContext context, String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HomeCredentialsDialog(email: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: Color(0xFF2E8B57)),
            SizedBox(width: 8),
            Text('بيانات دخول الابن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('احتفظ بهذه البيانات — لن تظهر مرة أخرى',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            _CredRow(label: 'الإيميل', value: email),
            const SizedBox(height: 10),
            _CredRow(label: 'كلمة المرور', value: password),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChildrenBloc>().add(const ChildrenCredentialsShown());
            },
            child: const Text('فهمت، أغلق'),
          ),
        ],
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _CredRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم النسخ إلى الحافظة'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
    );
  }
}
