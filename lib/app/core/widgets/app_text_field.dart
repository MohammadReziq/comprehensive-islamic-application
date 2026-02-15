import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// حقل إدخال نصي موحد
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final TextDirection? textDirection;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textDirection,
  });

  /// حقل بريد إلكتروني
  const AppTextField.email({
    super.key,
    this.controller,
    this.hint = 'example@email.com',
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  }) : label = 'البريد الإلكتروني',
       prefixIcon = Icons.email_outlined,
       suffix = null,
       obscureText = false,
       readOnly = false,
       enabled = true,
       maxLines = 1,
       maxLength = null,
       keyboardType = TextInputType.emailAddress,
       textInputAction = TextInputAction.next,
       onTap = null,
       textDirection = TextDirection.ltr;

  /// حقل كلمة سر
  factory AppTextField.password({
    Key? key,
    TextEditingController? controller,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    FocusNode? focusNode,
  }) {
    return _PasswordTextField(
      key: key,
      controller: controller,
      errorText: errorText,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
    );
  }

  /// حقل رقم هاتف
  const AppTextField.phone({
    super.key,
    this.controller,
    this.hint = '05XXXXXXXX',
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  }) : label = 'رقم الهاتف',
       prefixIcon = Icons.phone_outlined,
       suffix = null,
       obscureText = false,
       readOnly = false,
       enabled = true,
       maxLines = 1,
       maxLength = null,
       keyboardType = TextInputType.phone,
       textInputAction = TextInputAction.next,
       onTap = null,
       textDirection = TextDirection.ltr;

  /// حقل بحث
  const AppTextField.search({
    super.key,
    this.controller,
    this.hint = 'بحث...',
    this.onChanged,
    this.focusNode,
  }) : label = null,
       errorText = null,
       prefixIcon = Icons.search,
       suffix = null,
       obscureText = false,
       readOnly = false,
       enabled = true,
       maxLines = 1,
       maxLength = null,
       keyboardType = TextInputType.text,
       textInputAction = TextInputAction.search,
       validator = null,
       onSubmitted = null,
       onTap = null,
       textDirection = null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
            child: Text(
              label!,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textDirection: textDirection,
          focusNode: focusNode,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// حقل كلمة السر مع زر إظهار/إخفاء (StatefulWidget)
class _PasswordTextField extends AppTextField {
  const _PasswordTextField({
    super.key,
    super.controller,
    super.errorText,
    super.validator,
    super.onChanged,
    super.onSubmitted,
    super.focusNode,
  }) : super(
         label: 'كلمة المرور',
         prefixIcon: Icons.lock_outlined,
         obscureText: true,
         keyboardType: TextInputType.visiblePassword,
         textInputAction: TextInputAction.done,
       );

  @override
  Widget build(BuildContext context) {
    return _PasswordTextFieldStateful(
      controller: controller,
      errorText: errorText,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
    );
  }
}

class _PasswordTextFieldStateful extends StatefulWidget {
  final TextEditingController? controller;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const _PasswordTextFieldStateful({
    this.controller,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<_PasswordTextFieldStateful> createState() =>
      _PasswordTextFieldStatefulState();
}

class _PasswordTextFieldStatefulState
    extends State<_PasswordTextFieldStateful> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
          child: Text(
            'كلمة المرور',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          focusNode: widget.focusNode,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            errorText: widget.errorText,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }
}
