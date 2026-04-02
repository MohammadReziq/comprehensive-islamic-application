import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../bloc/competition_bloc.dart';
import '../bloc/competition_event.dart';
import '../bloc/competition_state.dart';

/// Dialog إنشاء مسابقة جديدة — مستخرجة من ManageCompetitionScreen.
class CreateCompetitionDialog extends StatefulWidget {
  const CreateCompetitionDialog({super.key, required this.mosqueId});

  final String mosqueId;

  @override
  State<CreateCompetitionDialog> createState() =>
      _CreateCompetitionDialogState();
}

class _CreateCompetitionDialogState extends State<CreateCompetitionDialog> {
  final _nameCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onCreate() {
    if (_nameCtrl.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل جميع الحقول')),
      );
      return;
    }
    Navigator.pop(context);
    context.read<CompetitionBloc>().add(CreateCompetition(
          mosqueId: widget.mosqueId,
          nameAr: _nameCtrl.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
        ));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_startDate ?? now),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => isStart ? _startDate = d : _endDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompetitionBloc, CompetitionState>(
      listener: (_, state) {
        if (state is CompetitionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: AlertDialog(
        title: const Text('مسابقة جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المسابقة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _startDate == null
                      ? 'تاريخ البداية'
                      : DateFormat('yyyy/MM/dd').format(_startDate!),
                ),
                onTap: () => _pickDate(isStart: true),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _endDate == null
                      ? 'تاريخ النهاية'
                      : DateFormat('yyyy/MM/dd').format(_endDate!),
                ),
                onTap: () => _pickDate(isStart: false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(onPressed: _onCreate, child: const Text('إنشاء')),
        ],
      ),
    );
  }
}
