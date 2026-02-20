import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../data/repositories/child_repository.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';

// ═══════════════════════════════════════════════════════════════════
/// 📁 lib/app/features/parent/presentation/screens/add_child_screen.dart
// ═══════════════════════════════════════════════════════════════════
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  int _age = 8;
  bool _createAccount = false;
  bool _loading = false;
  bool _showPass = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل اسم الطفل'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    context.read<ChildrenBloc>().add(
      ChildrenAdd(
        name: name,
        age: _age,
        email: _createAccount ? _emailCtrl.text.trim() : null,
        password: _createAccount ? _passCtrl.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChildrenBloc, ChildrenState>(
      listener: (context, state) {
        if (state is ChildrenLoaded || state is ChildrenLoadedWithCredentials) {
          setState(() => _loading = false);
          context.pop();
        }
        if (state is ChildrenError) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildCard(
                        children: [
                          _label('اسم الطفل'),
                          _field(
                            _nameCtrl,
                            'مثال: أحمد محمد',
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(height: 16),
                          _label('العمر'),
                          _agePicker(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'إنشاء حساب للابن',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A2B3C),
                                ),
                              ),
                              Switch(
                                value: _createAccount,
                                onChanged: (v) =>
                                    setState(() => _createAccount = v),
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                          if (_createAccount) ...[
                            const SizedBox(height: 12),
                            Text(
                              'سيتمكن الابن من تسجيل الدخول بهذه البيانات',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _label('الإيميل'),
                            _field(
                              _emailCtrl,
                              'example@email.com',
                              icon: Icons.email_rounded,
                              type: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _label('كلمة المرور'),
                            TextField(
                              controller: _passCtrl,
                              obscureText: !_showPass,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPass
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _showPass = !_showPass),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'إضافة الطفل',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
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

  Widget _buildHeader(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'إضافة طفل',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A2B3C),
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    IconData? icon,
    TextInputType? type,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _agePicker() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _age > 3 ? () => setState(() => _age--) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text(
            '$_age سنة',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
            ),
          ),
          IconButton(
            onPressed: _age < 18 ? () => setState(() => _age++) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
