// شاشة إنشاء طلب تصحيح — لولي الأمر (من بطاقة الطفل)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../injection_container.dart';
import '../../../parent/data/repositories/child_repository.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';
import '../../../../models/mosque_model.dart';
import '../bloc/correction_bloc.dart';
import '../bloc/correction_event.dart';
import '../bloc/correction_state.dart';

class RequestCorrectionScreen extends StatefulWidget {
  const RequestCorrectionScreen({
    super.key,
    required this.childId,
    this.childName,
  });

  final String childId;
  final String? childName;

  @override
  State<RequestCorrectionScreen> createState() => _RequestCorrectionScreenState();
}

class _RequestCorrectionScreenState extends State<RequestCorrectionScreen> {
  List<MosqueModel> _mosques = [];
  bool _loadingMosques = true;
  String? _errorMosques;

  MosqueModel? _selectedMosque;
  Prayer _selectedPrayer = Prayer.fajr;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChildMosques();
  }

  Future<void> _loadChildMosques() async {
    setState(() {
      _loadingMosques = true;
      _errorMosques = null;
    });
    try {
      final ids = await sl<ChildRepository>().getChildMosqueIds(widget.childId);
      if (ids.isEmpty) {
        if (mounted) setState(() {
          _loadingMosques = false;
          _errorMosques = 'اربط ابنك بمسجد أولاً من بطاقة الطفل';
        });
        return;
      }
      final list = await sl<MosqueRepository>().getMosquesByIds(ids);
      if (mounted) setState(() {
        _mosques = list;
        _loadingMosques = false;
        if (list.isNotEmpty) _selectedMosque = list.first;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loadingMosques = false;
        _errorMosques = 'حدث خطأ في جلب المساجد';
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedMosque == null) return;
    final mosqueId = _selectedMosque!.id;
    context.read<CorrectionBloc>().add(CreateCorrectionRequest(
          childId: widget.childId,
          mosqueId: mosqueId,
          prayer: _selectedPrayer,
          prayerDate: _selectedDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
          appBar: AppBar(
            title: const Text('طلب تصحيح حضور'),
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: _loadingMosques
              ? const Center(child: CircularProgressIndicator())
              : _errorMosques != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingLG),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 56, color: Colors.orange.shade700),
                            const SizedBox(height: 16),
                            Text(
                              _errorMosques!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => context.pop(),
                              child: const Text('رجوع'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : BlocConsumer<CorrectionBloc, CorrectionState>(
                      listener: (context, state) {
                        if (state is CorrectionActionSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          context.pop();
                        } else if (state is CorrectionError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        final isLoading = state is CorrectionLoading;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(AppDimensions.paddingLG),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.childName != null) ...[
                                Text(
                                  'طفل: ${widget.childName!}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.paddingXL),
                              ],
                              const Text(
                                'المسجد',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<MosqueModel>(
                                value: _selectedMosque,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                                items: _mosques
                                    .map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m.name),
                                        ))
                                    .toList(),
                                onChanged: isLoading
                                    ? null
                                    : (m) => setState(() => _selectedMosque = m),
                              ),
                              const SizedBox(height: AppDimensions.paddingLG),
                              const Text(
                                'الصلاة',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Prayer>(
                                value: _selectedPrayer,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                                items: Prayer.values
                                    .map((p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p.nameAr),
                                        ))
                                    .toList(),
                                onChanged: isLoading
                                    ? null
                                    : (p) =>
                                        setState(() => _selectedPrayer = p!),
                              ),
                              const SizedBox(height: AppDimensions.paddingLG),
                              const Text(
                                'التاريخ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: isLoading
                                    ? null
                                    : () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime.now()
                                              .subtract(const Duration(days: 30)),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null)
                                          setState(() => _selectedDate = date);
                                      },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                  child: Text(
                                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingLG),
                              const Text(
                                'ملاحظة (اختياري)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _noteController,
                                maxLines: 2,
                                enabled: !isLoading,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'مثلاً: كان حاضراً ولم يُسجّل',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingXL),
                              FilledButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _submit(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('إرسال طلب التصحيح'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
    );
  }
}
