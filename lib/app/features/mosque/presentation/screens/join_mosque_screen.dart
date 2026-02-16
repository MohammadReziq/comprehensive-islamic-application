import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/mosque_bloc.dart';
import '../bloc/mosque_event.dart';
import '../bloc/mosque_state.dart';

/// شاشة الانضمام لمسجد بكود الدعوة
class JoinMosqueScreen extends StatefulWidget {
  const JoinMosqueScreen({super.key});

  @override
  State<JoinMosqueScreen> createState() => _JoinMosqueScreenState();
}

class _JoinMosqueScreenState extends State<JoinMosqueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      context.read<MosqueBloc>().add(
            MosqueJoinByCode(_codeController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.joinMosque),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<MosqueBloc, MosqueState>(
          listener: (context, state) {
            if (state is MosqueError) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is MosqueLoaded && _isSubmitting) {
              setState(() => _isSubmitting = false);
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final loading = state is MosqueLoading && _isSubmitting;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppDimensions.paddingXL),
                    Text(
                      'أدخل كود الدعوة الذي أعطاك إياه مدير المسجد',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    AppTextField(
                      controller: _codeController,
                      label: AppStrings.inviteCode,
                      hint: 'مثال: ABCD1234',
                      prefixIcon: Icons.vpn_key,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'أدخل كود الدعوة';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingXXL),
                    AppButton(
                      text: 'انضمام',
                      onPressed: loading ? null : _onSubmit,
                      isLoading: loading,
                      icon: Icons.group_add,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
