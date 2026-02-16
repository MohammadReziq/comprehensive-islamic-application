import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/qr_display.dart';
import '../../../../models/child_model.dart';
import '../../data/repositories/child_repository.dart';
import '../../../../injection_container.dart';

/// بطاقة الطفل مع QR
class ChildCardScreen extends StatefulWidget {
  const ChildCardScreen({super.key, this.childId, this.child});

  final String? childId;
  final ChildModel? child;

  @override
  State<ChildCardScreen> createState() => _ChildCardScreenState();
}

class _ChildCardScreenState extends State<ChildCardScreen> {
  ChildModel? _child;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _child = widget.child;
      _loading = false;
    } else if (widget.childId != null) {
      _loadChild();
    } else {
      _error = 'معرف الطفل غير متوفر';
      _loading = false;
    }
  }

  Future<void> _loadChild() async {
    if (widget.childId == null) return;
    try {
      final c = await sl<ChildRepository>().getMyChild(widget.childId!);
      if (mounted) setState(() {
        _child = c;
        _loading = false;
        if (c == null) _error = 'الطفل غير موجود';
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بطاقة الطفل'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_child != null)
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _child!.qrCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ كود QR'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                tooltip: 'نسخ الكود',
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _child == null
                    ? const Center(child: Text('الطفل غير موجود'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDimensions.paddingLG),
                        child: Column(
                          children: [
                            Text(
                              _child!.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_child!.age} سنة · ${_child!.totalPoints} نقطة',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingXL),
                            QrDisplay(
                              data: _child!.qrCode,
                              size: 220,
                              childName: _child!.name,
                              showDecorations: true,
                            ),
                            const SizedBox(height: AppDimensions.paddingMD),
                            Text(
                              'امسح البطاقة عند المشرف لتسجيل الحضور',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
