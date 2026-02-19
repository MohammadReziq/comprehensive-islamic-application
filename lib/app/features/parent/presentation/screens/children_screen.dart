import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/child_repository.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../models/child_model.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';

/// شاشة أطفالي
class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildrenBloc>().add(const ChildrenLoad());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أطفالي'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/parent/children/add'),
            ),
          ],
        ),
        body: BlocConsumer<ChildrenBloc, ChildrenState>(
          listener: (context, state) {
            if (state is ChildrenError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state is ChildrenLoadedWithCredentials) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showChildCredentialsDialog(
                  context,
                  state.email,
                  state.password,
                );
              });
            }
          },
          builder: (context, state) {
            if (state is ChildrenInitial || state is ChildrenLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ChildrenError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: AppDimensions.paddingMD),
                      ElevatedButton(
                        onPressed: () => context.read<ChildrenBloc>().add(const ChildrenLoad()),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is! ChildrenLoaded && state is! ChildrenLoadedWithCredentials) {
              return const SizedBox.shrink();
            }
            final children = state is ChildrenLoaded
                ? state.children
                : (state as ChildrenLoadedWithCredentials).children;

            if (children.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: AppDimensions.paddingMD),
                    Text(
                      'لا يوجد أطفال مضافون بعد',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    FilledButton.icon(
                      onPressed: () => context.push('/parent/children/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة طفل'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              itemCount: children.length,
              itemBuilder: (context, i) {
                final child = children[i];
                return _ChildCard(
                  child: child,
                  onTap: () => context.push('/parent/children/${child.id}/card'),
                  onLinkMosque: () => _showLinkMosqueDialog(context, child),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showChildCredentialsDialog(
    BuildContext context,
    String email,
    String password,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('بيانات دخول ابنك'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('البريد: $email'),
                const SizedBox(height: 8),
                Text('كلمة المرور: $password'),
                const SizedBox(height: 16),
                Text(
                  'احفظها في مكان آمن لاستخدامها عند دخول ابنك.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                context.read<ChildrenBloc>().add(const ChildrenCredentialsShown());
                Navigator.of(ctx).pop();
              },
              child: const Text('تم'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkMosqueDialog(BuildContext context, ChildModel child) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ربط بمسجد'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'كود المسجد',
              hintText: 'أدخل الكود من إدارة المسجد',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await sl<ChildRepository>().linkChildToMosque(
                    childId: child.id,
                    mosqueCode: code,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم ربط الطفل بالمسجد'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context.read<ChildrenBloc>().add(const ChildrenLoad());
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('ربط'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.onTap,
    required this.onLinkMosque,
  });

  final ChildModel child;
  final VoidCallback onTap;
  final VoidCallback onLinkMosque;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            child.name.isNotEmpty ? child.name[0] : '؟',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(child.name),
        subtitle: Text('${child.age} سنة · ${child.totalPoints} نقطة'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.mosque),
              onPressed: onLinkMosque,
              tooltip: 'ربط بمسجد',
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              onPressed: onTap,
              tooltip: 'بطاقة QR',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
