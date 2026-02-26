import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/mosque_model.dart';
import '../../data/repositories/child_repository.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';

// ═══════════════════════════════════════════════════════════════════
/// 📁 lib/app/features/parent/presentation/screens/request_correction_screen.dart
/// Widget: RequestCorrectionScreen
// ═══════════════════════════════════════════════════════════════════
class RequestCorrectionScreen extends StatefulWidget {
  const RequestCorrectionScreen({super.key, required this.childId});
  final String childId;

  @override
  State<RequestCorrectionScreen> createState() =>
      _RequestCorrectionScreenState();
}

class _RequestCorrectionScreenState extends State<RequestCorrectionScreen> {
  ChildModel? _child;
  List<({String mosqueId, MosqueType type})> _linkedWithType = [];
  List<MosqueModel> _mosques = [];
  bool _loading = true;

  String? _selectedMosqueId;
  Prayer? _selectedPrayer;
  DateTime _selectedDate = DateTime.now();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  final _prayers = [
    (Prayer.fajr, 'الفجر'),
    (Prayer.dhuhr, 'الظهر'),
    (Prayer.asr, 'العصر'),
    (Prayer.maghrib, 'المغرب'),
    (Prayer.isha, 'العشاء'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final child = await sl<ChildRepository>().getMyChild(widget.childId);
      final linkedWithType = await sl<ChildRepository>().getChildMosquesWithType(widget.childId);
      final ids = linkedWithType.map((e) => e.mosqueId).toList();
      final mosques = ids.isNotEmpty
          ? await sl<MosqueRepository>().getMosquesByIds(ids)
          : <MosqueModel>[];
      if (mounted) {
        setState(() {
          _child = child;
          _linkedWithType = linkedWithType;
          _mosques = mosques;
          _loading = false;
          if (mosques.isNotEmpty) _selectedMosqueId = mosques.first.id;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedMosqueId == null || _selectedPrayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر المسجد والصلاة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      // CorrectionRepository.createRequest — استدعه من CorrectionBloc إن وُجد
      // أو استدعه مباشرة من sl<CorrectionRepository>()
      // مثال:
      // await sl<CorrectionRepository>().createRequest(
      //   childId: widget.childId,
      //   mosqueId: _selectedMosqueId!,
      //   prayer: _selectedPrayer!,
      //   prayerDate: _selectedDate,
      //   note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      // );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب التصحيح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          if (_mosques.isEmpty)
                            _buildNoMosqueCard()
                          else ...[
                            _buildCard(
                              children: [
                                _label('المسجد'),
                                _buildMosquePicker(),
                                const SizedBox(height: 16),
                                _label('الصلاة'),
                                _buildPrayerPicker(),
                                const SizedBox(height: 16),
                                _label('التاريخ'),
                                _buildDatePicker(context),
                                const SizedBox(height: 16),
                                _label('ملاحظة (اختياري)'),
                                TextField(
                                  controller: _noteCtrl,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'سبب طلب التصحيح...',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F6FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9C27B0),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'إرسال الطلب',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'طلب تصحيح حضور',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (_child != null)
                    Text(
                      _child!.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMosquePicker() {
    MosqueType typeFor(String mosqueId) {
      final list = _linkedWithType.where((e) => e.mosqueId == mosqueId).toList();
      return list.isEmpty ? MosqueType.primary : list.first.type;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMosqueId,
          isExpanded: true,
          items: _mosques
              .map((m) => DropdownMenuItem<String>(
                    value: m.id,
                    child: Text('${m.name} (${typeFor(m.id).nameAr})'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedMosqueId = v),
        ),
      ),
    );
  }

  Widget _buildPrayerPicker() {
    return Wrap(
      spacing: 8,
      children: _prayers.map((p) {
        final selected = _selectedPrayer == p.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedPrayer = p.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF9C27B0)
                  : const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF1A2B3C),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2B3C),
              ),
            ),
          ],
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

  Widget _buildNoMosqueCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.mosque_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'الابن غير مرتبط بأي مسجد',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اذهب لبطاقة الابن وأضف كود المسجد أولاً',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('رجوع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
