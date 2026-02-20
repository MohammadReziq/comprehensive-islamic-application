import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/map_picker_screen.dart';
import '../bloc/mosque_bloc.dart';
import '../bloc/mosque_event.dart';
import '../bloc/mosque_state.dart';

/// شاشة إنشاء مسجد جديد
class CreateMosqueScreen extends StatefulWidget {
  const CreateMosqueScreen({super.key});

  @override
  State<CreateMosqueScreen> createState() => _CreateMosqueScreenState();
}

class _CreateMosqueScreenState extends State<CreateMosqueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSubmitting = false;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تحديد موقع المسجد على الخريطة'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFE67E22),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    context.read<MosqueBloc>().add(
          MosqueCreate(
            name: _nameController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            lat: _selectedLat!,
            lng: _selectedLng!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.createMosque),
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
                    AppTextField(
                      controller: _nameController,
                      label: AppStrings.mosqueName,
                      hint: 'مثال: مسجد الرحمة',
                      prefixIcon: Icons.mosque,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'أدخل اسم المسجد';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    AppTextField(
                      controller: _addressController,
                      label: AppStrings.mosqueAddress,
                      hint: 'اختياري',
                      prefixIcon: Icons.location_on_outlined,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    // موقع المسجد إلزامي — شاشة كاملة تبدأ من موقعك، اضغط على مكان المسجد بالضبط
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<MapPickerResult>(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => MapPickerScreen(
                              title: 'تحديد موقع المسجد',
                              initialLat: _selectedLat,
                              initialLng: _selectedLng,
                            ),
                          ),
                        );
                        if (!mounted || result == null) return;
                        setState(() {
                          _selectedLat = result.lat;
                          _selectedLng = result.lng;
                        });
                      },
                      icon: Icon(_selectedLat != null ? Icons.edit_location_alt : Icons.map_outlined),
                      label: Text(
                        _selectedLat != null && _selectedLng != null
                            ? 'تم تعيين الموقع — اضغط لتغييره'
                            : 'تحديد موقع المسجد على الخريطة (إلزامي)',
                      ),
                    ),
                    if (_selectedLat != null && _selectedLng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'الإحداثيات: ${_selectedLat!.toStringAsFixed(5)}, ${_selectedLng!.toStringAsFixed(5)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    const SizedBox(height: AppDimensions.paddingXXL),
                    AppButton(
                      text: 'إنشاء الطلب',
                      onPressed: loading ? null : _onSubmit,
                      isLoading: loading,
                      icon: Icons.add_circle_outline,
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
