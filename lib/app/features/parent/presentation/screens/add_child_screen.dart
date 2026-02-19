import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';

/// شاشة إضافة طفل
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final age = int.tryParse(_ageController.text.trim());
      if (age == null || age < 1 || age > 19) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('العمر بين 1 و 19')),
        );
        return;
      }
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      context.read<ChildrenBloc>().add(
            ChildrenAdd(
              name: _nameController.text.trim(),
              age: age,
              email: email.isEmpty ? null : email,
              password: password.isEmpty ? null : password,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة طفل'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocListener<ChildrenBloc, ChildrenState>(
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
            if (state is ChildrenLoaded || state is ChildrenLoadedWithCredentials) {
              context.pop();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: 'اسم الطفل',
                    hint: 'أدخل الاسم',
                    prefixIcon: Icons.person,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل الاسم';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  AppTextField(
                    controller: _ageController,
                    label: 'العمر',
                    hint: '1 - 19',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.cake,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل العمر';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1 || n > 19) return 'العمر بين 1 و 19';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  AppTextField(
                    controller: _emailController,
                    label: 'بريد الابن (اختياري — لحساب دخول له)',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  AppTextField(
                    controller: _passwordController,
                    label: 'كلمة سر الابن (اختياري)',
                    hint: '••••••••',
                    obscureText: true,
                    prefixIcon: Icons.lock,
                  ),
                  const SizedBox(height: AppDimensions.paddingXXL),
                  AppButton(
                    text: 'إضافة',
                    onPressed: _onSubmit,
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
