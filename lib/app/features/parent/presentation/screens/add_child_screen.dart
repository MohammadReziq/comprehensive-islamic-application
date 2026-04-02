import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';
import '../widgets/child_credentials_dialog.dart';
import '../widgets/feature_gradient_header.dart';
import '../widgets/add_child_form_card.dart';
import '../widgets/add_child_account_card.dart';

/// شاشة إضافة ابن
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  int _age = 12;
  bool _createAccount = false;
  bool _loading = false;
  bool _showPass = false;
  bool _credentialsHandled = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم الابن'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_createAccount) {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل إيميل الابن لإنشاء الحساب'), behavior: SnackBarBehavior.floating));
        return;
      }
      if (pass.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور 6 أحرف على الأقل'), behavior: SnackBarBehavior.floating));
        return;
      }
    }
    setState(() => _loading = true);
    context.read<ChildrenBloc>().add(ChildrenAdd(
      name: name, age: _age,
      email: _createAccount ? _emailCtrl.text.trim() : null,
      password: _createAccount ? _passCtrl.text.trim() : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChildrenBloc, ChildrenState>(
      listener: (context, state) {
        if (state is ChildrenLoaded && !_credentialsHandled) {
          setState(() => _loading = false);
          context.pop();
        }
        if (state is ChildrenLoadedWithCredentials) {
          setState(() => _loading = false);
          _credentialsHandled = true;
          ChildCredentialsDialog.show(
            context: context, email: state.email, password: state.password,
            onDismiss: () {
              context.read<ChildrenBloc>().add(const ChildrenCredentialsShown());
              if (context.mounted) context.pop();
            },
          );
        }
        if (state is ChildrenError) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: FeatureGradientHeader(title: 'إضافة ابن'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      AddChildFormCard(
                        nameController: _nameCtrl,
                        age: _age,
                        onAgeChanged: (v) => setState(() => _age = v),
                      ),
                      const SizedBox(height: 16),
                      AddChildAccountCard(
                        createAccount: _createAccount,
                        onCreateAccountChanged: (v) => setState(() => _createAccount = v),
                        emailController: _emailCtrl,
                        passwordController: _passCtrl,
                        showPassword: _showPass,
                        onTogglePassword: () => setState(() => _showPass = !_showPass),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('إضافة الابن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
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
