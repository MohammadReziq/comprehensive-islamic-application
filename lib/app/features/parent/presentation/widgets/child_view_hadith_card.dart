import 'package:flutter/material.dart';
import '../../../../core/constants/hadiths_prayer.dart';

/// بطاقة الحديث اليومي عن الصلاة — تصميم عصري مع إطار إسلامي
class ChildViewHadithCard extends StatefulWidget {
  const ChildViewHadithCard({super.key});

  @override
  State<ChildViewHadithCard> createState() => _ChildViewHadithCardState();
}

class _ChildViewHadithCardState extends State<ChildViewHadithCard>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    _currentIndex = dayOfYear % HadithPrayer.list.length;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.value = 1.0;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextHadith() async {
    await _animController.reverse();
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % HadithPrayer.list.length;
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final hadith = HadithPrayer.list[_currentIndex];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFF9FBF2), Color(0xFFF0F7E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B57).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF2E8B57).withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // زخرفة خلفية
          Positioned(
            top: -20,
            left: -20,
            child: Icon(
              Icons.menu_book_rounded,
              color: const Color(0xFF2E8B57).withValues(alpha: 0.04),
              size: 120,
            ),
          ),
          Positioned(
            bottom: -10,
            right: -10,
            child: Icon(
              Icons.auto_stories_rounded,
              color: const Color(0xFF2E8B57).withValues(alpha: 0.03),
              size: 80,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2E8B57).withValues(alpha: 0.15),
                            const Color(0xFF2E8B57).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          color: Color(0xFF2E8B57), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📖  حديث عن الصلاة',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A2B3C),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'تعلّم من سنة رسول الله ﷺ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // رقم الحديث
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B57).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${HadithPrayer.list.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E8B57),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // نص الحديث مع أنيميشن
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // نص الحديث
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF2E8B57).withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E8B57).withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // علامة اقتباس علوية
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  '❝',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: const Color(0xFF2E8B57).withValues(alpha: 0.3),
                                    height: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hadith.text,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A2B3C),
                                  height: 1.9,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                              const SizedBox(height: 4),
                              // علامة اقتباس سفلية
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Text(
                                  '❞',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: const Color(0xFF2E8B57).withValues(alpha: 0.3),
                                    height: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // الراوي والمصدر في بطاقات صغيرة
                        Row(
                          children: [
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.person_outline_rounded,
                                text: hadith.narrator,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _GradeChip(grade: hadith.grade),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _InfoChip(
                          icon: Icons.library_books_outlined,
                          text: hadith.source,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // زر التالي
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _nextHadith,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text(
                      'حديث آخر',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2E8B57),
                      backgroundColor: const Color(0xFF2E8B57).withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2E8B57)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String grade;
  const _GradeChip({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E8B57).withValues(alpha: 0.15),
            const Color(0xFF2E8B57).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        grade,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2E8B57),
        ),
      ),
    );
  }
}
