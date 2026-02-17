import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../injection_container.dart';
import '../../data/models/mosque_student_model.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';

/// قائمة طلاب المسجد
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<MosqueStudentModel> _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final mosqueBloc = context.read<MosqueBloc>();
    final mosqueState = mosqueBloc.state;
    if (mosqueState is! MosqueLoaded) {
      setState(() {
        _loading = false;
        _error = 'لم يتم تحديد المسجد';
      });
      return;
    }
    final approved = mosqueState.mosques.where((m) => m.status == MosqueStatus.approved).firstOrNull;
    if (approved == null) {
      setState(() {
        _loading = false;
        _error = 'لا يوجد مسجد معتمد';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await sl<SupervisorRepository>().getMosqueStudents(approved.id);
      if (mounted) setState(() {
        _students = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الطلاب'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: AppDimensions.paddingMD),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: AppDimensions.paddingMD),
                            Text(
                              'لا يوجد طلاب مرتبطين بهذا المسجد بعد',
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ولي الأمر يربط أطفاله بكود المسجد',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.paddingMD),
                        itemCount: _students.length,
                        itemBuilder: (context, i) {
                          final s = _students[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                child: Text(
                                  s.child.name.isNotEmpty ? s.child.name[0] : '؟',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              title: Text(s.child.name),
                              subtitle: Text('رقم ${s.localNumber} · ${s.child.totalPoints} نقطة'),
                              onTap: () => context.push('/supervisor/child/${s.child.id}'),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
