import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/imam_repository.dart';
import '../bloc/imam_bloc.dart';
import '../bloc/imam_event.dart';
import '../bloc/imam_state.dart';

/// شاشة إعداد نقاط الصلوات للمسجد (الإمام فقط)
class PrayerPointsSettingsScreen extends StatefulWidget {
  const PrayerPointsSettingsScreen({
    super.key,
    required this.mosqueId,
    this.mosqueName,
  });

  final String mosqueId;
  final String? mosqueName;

  @override
  State<PrayerPointsSettingsScreen> createState() =>
      _PrayerPointsSettingsScreenState();
}

class _PrayerPointsSettingsScreenState extends State<PrayerPointsSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<Prayer, TextEditingController> _controllers = {};
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    for (final p in Prayer.values) {
      _controllers[p] = TextEditingController(text: '10');
    }
    _loadPoints();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPoints() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final points =
          await sl<ImamRepository>().getPrayerPointsForMosque(widget.mosqueId);
      if (mounted) {
        for (final e in points.entries) {
          _controllers[e.key]?.text = '${e.value}';
        }
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Map<Prayer, int> _getPointsFromFields() {
    final map = <Prayer, int>{};
    for (final p in Prayer.values) {
      final c = _controllers[p]!;
      final v = int.tryParse(c.text.trim());
      map[p] = (v != null && v >= 0) ? v : 10;
    }
    return map;
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final points = _getPointsFromFields();
      context.read<ImamBloc>().add(
            UpdateMosquePrayerPoints(widget.mosqueId, points),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mosqueName != null
              ? 'نقاط الصلوات — ${widget.mosqueName}'
              : 'نقاط الصلوات'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocListener<ImamBloc, ImamState>(
          listener: (context, state) {
            if (state is ImamActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state is ImamError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingLG),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_loadError!, textAlign: TextAlign.center),
                            const SizedBox(height: AppDimensions.paddingMD),
                            FilledButton(
                              onPressed: _loadPoints,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          Card(
                            color: AppColors.warningLight,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppDimensions.paddingMD),
                              child: Text(
                                'التغيير ينطبق فوراً على الحضور الجديد (بما فيه المسابقة الجارية إن وُجدت).',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingLG),
                          ...Prayer.values.map((p) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppDimensions.paddingMD),
                                child: AppTextField(
                                  controller: _controllers[p],
                                  label: p.nameAr,
                                  hint: '0 - 999',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.star_outline,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'أدخل رقماً';
                                    }
                                    final n = int.tryParse(v.trim());
                                    if (n == null || n < 0 || n > 999) {
                                      return 'بين 0 و 999';
                                    }
                                    return null;
                                  },
                                ),
                              )),
                          const SizedBox(height: AppDimensions.paddingXXL),
                          AppButton(
                            text: 'حفظ',
                            onPressed: _save,
                            icon: Icons.save,
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
