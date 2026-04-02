import 'package:flutter/material.dart';

/// كارد معلومات الابن الأساسية (الاسم + العمر)
class AddChildFormCard extends StatelessWidget {
  final TextEditingController nameController;
  final int age;
  final ValueChanged<int> onAgeChanged;

  const AddChildFormCard({
    super.key,
    required this.nameController,
    required this.age,
    required this.onAgeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _card(
      children: [
        _label('اسم الابن'),
        _field(nameController, 'مثال: أحمد محمد', icon: Icons.person_rounded),
        const SizedBox(height: 16),
        _label('العمر'),
        _agePicker(),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C))),
  );

  Widget _field(TextEditingController ctrl, String hint, {IconData? icon}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _agePicker() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: age > 3 ? () => onAgeChanged(age - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text('$age سنة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
          IconButton(
            onPressed: age < 18 ? () => onAgeChanged(age + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
