import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/map_picker_screen.dart'; // showMapPickerDialog, MapPickerResult
import '../../../../injection_container.dart';
import '../../../../models/mosque_model.dart';
import '../../presentation/bloc/imam_bloc.dart';
import '../../presentation/bloc/imam_event.dart';
import '../../presentation/bloc/imam_state.dart';

/// شاشة إعدادات المسجد (الاسم، العنوان، نافذة الحضور)
class ImamMosqueSettingsScreen extends StatefulWidget {
  const ImamMosqueSettingsScreen({
    super.key,
    required this.mosqueId,
    required this.mosque,
  });

  final String mosqueId;
  final MosqueModel mosque;

  @override
  State<ImamMosqueSettingsScreen> createState() =>
      _ImamMosqueSettingsScreenState();
}

class _ImamMosqueSettingsScreenState extends State<ImamMosqueSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _windowCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.mosque.name);
    _addressCtrl = TextEditingController(text: widget.mosque.address ?? '');
    _windowCtrl = TextEditingController(
      text: (widget.mosque.attendanceWindowMinutes).toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _windowCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ImamBloc>().add(
      UpdateMosqueSettings(
        mosqueId: widget.mosqueId,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : null,
        attendanceWindowMinutes: int.parse(_windowCtrl.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ImamBloc>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text('إعدادات المسجد', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: BlocListener<ImamBloc, ImamState>(
            listener: (context, state) {
              if (state is MosqueSettingsUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم الحفظ ✅', style: GoogleFonts.cairo()),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).pop();
              }
              if (state is ImamError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: GoogleFonts.cairo()),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ملاحظة
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMD),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'التغييرات ستُطبّق فوراً على المسجد.',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),

                    // اسم المسجد
                    AppTextField(
                      controller: _nameCtrl,
                      label: 'اسم المسجد',
                      hint: 'أدخل اسم المسجد',
                      prefixIcon: Icons.mosque_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'اسم المسجد مطلوب'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),

                    // العنوان
                    AppTextField(
                      controller: _addressCtrl,
                      label: 'العنوان',
                      hint: 'عنوان المسجد (اختياري)',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),

                    // موقع المسجد على الخريطة (حوار مربّع + موقعك الحالي)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await showMapPickerDialog(
                          context,
                          title: 'تحديد موقع المسجد',
                          initialLat: widget.mosque.lat,
                          initialLng: widget.mosque.lng,
                        );
                        if (!mounted || result == null) return;
                        context.read<ImamBloc>().add(
                          UpdateMosqueSettings(
                            mosqueId: widget.mosqueId,
                            lat: result.lat,
                            lng: result.lng,
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        widget.mosque.lat != null && widget.mosque.lng != null
                            ? 'تعديل موقع المسجد على الخريطة'
                            : 'تحديد موقع المسجد على الخريطة',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),

                    // نافذة الحضور
                    AppTextField(
                      controller: _windowCtrl,
                      label: 'نافذة الحضور (بالدقائق)',
                      hint: '1 - 120',
                      prefixIcon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'أدخل قيمة';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1 || n > 120) {
                          return 'يجب أن تكون بين 1 و 120 دقيقة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'نافذة الحضور هي المدة التي يُقبل فيها تسجيل الحضور بعد وقت الصلاة.',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXXL),

                    BlocBuilder<ImamBloc, ImamState>(
                      builder: (context, state) {
                        return AppButton(
                          text: 'حفظ',
                          onPressed: _save,
                          isLoading: state is ImamLoading,
                          icon: Icons.save_outlined,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
