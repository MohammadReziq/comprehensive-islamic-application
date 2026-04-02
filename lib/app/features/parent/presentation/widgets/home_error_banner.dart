import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';

class HomeErrorBanner extends StatelessWidget {
  final String message;
  
  const HomeErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تعذّر تحميل بيانات الأبناء',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade700),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<ChildrenBloc>().add(const ChildrenLoad()),
            child: Text(
              'إعادة المحاولة',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade600,
                  decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
