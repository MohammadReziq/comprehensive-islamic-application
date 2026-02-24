// lib/app/features/notes/presentation/screens/send_note_screen.dart
// إرسال ملاحظة — للمشرف/الإمام

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';

class SendNoteScreen extends StatefulWidget {
  final List<ChildModel> children;
  final String mosqueId;

  const SendNoteScreen({
    super.key,
    required this.children,
    required this.mosqueId,
  });

  @override
  State<SendNoteScreen> createState() => _SendNoteScreenState();
}

class _SendNoteScreenState extends State<SendNoteScreen> {
  final _messageController = TextEditingController();
  ChildModel? _selectedChild;

  // قوالب رسائل جاهزة
  static const _templates = [
    'تلاوته اليوم رائعة 🌟',
    'حضوره منتظم ومتميز 👏',
    'يحتاج إلى تشجيع إضافي 💪',
    'أداؤه في الحفظ ممتاز 📖',
    'يتفاعل بشكل إيجابي مع زملائه 🤝',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotesBloc>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('إرسال ملاحظة'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: BlocConsumer<NotesBloc, NotesState>(
            listener: (context, state) {
              if (state is NotesSent) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال الملاحظة بنجاح ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else if (state is NotesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── اختيار الابن ───
                    const Text(
                      'اختر الابن',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ChildModel>(
                      value: _selectedChild,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'اختر ابناً',
                      ),
                      items: widget.children.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedChild = v),
                    ),

                    const SizedBox(height: 20),

                    // ─── قوالب جاهزة ───
                    const Text(
                      'قوالب سريعة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _templates.map((t) {
                        return ActionChip(
                          label: Text(t, style: const TextStyle(fontSize: 13)),
                          onPressed: () {
                            _messageController.text = t;
                            setState(() {});
                          },
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ─── نص الملاحظة ───
                    const Text(
                      'الملاحظة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'اكتب ملاحظتك هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── زر الإرسال ───
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: state is NotesLoading
                            ? null
                            : () {
                                if (_selectedChild == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('اختر ابناً أولاً')),
                                  );
                                  return;
                                }
                                if (_messageController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('اكتب الملاحظة أولاً')),
                                  );
                                  return;
                                }
                                context.read<NotesBloc>().add(SendNote(
                                  childId:  _selectedChild!.id,
                                  mosqueId: widget.mosqueId,
                                  message:  _messageController.text.trim(),
                                ));
                              },
                        icon: state is NotesLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: const Text('إرسال الملاحظة',
                            style: TextStyle(fontSize: 16)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
