import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// كارد إنشاء حساب للابن (إيميل + كلمة مرور)
class AddChildAccountCard extends StatelessWidget {
  final bool createAccount;
  final ValueChanged<bool> onCreateAccountChanged;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onTogglePassword;

  const AddChildAccountCard({
    super.key,
    required this.createAccount,
    required this.onCreateAccountChanged,
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إنشاء حساب للابن',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C)),
              ),
              Switch(
                value: createAccount,
                onChanged: onCreateAccountChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (createAccount) ...[
            const SizedBox(height: 12),
            Text('سيتمكن الابن من تسجيل الدخول بهذه البيانات', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            _label('الإيميل'),
            _field(emailController, 'example@email.com', icon: Icons.email_rounded, type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _label('كلمة المرور'),
            TextField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: onTogglePassword,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C))),
  );

  Widget _field(TextEditingController ctrl, String hint, {IconData? icon, TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
