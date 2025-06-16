import 'package:flutter/material.dart';
import 'modern_progress_chip.dart';

/// Examples of how to use the ModernProgressChip with different styles
/// This file demonstrates various implementations based on modern design trends
class ModernProgressExamples extends StatelessWidget {
  const ModernProgressExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مؤشرات التقدم الحديثة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              'أنواع مؤشرات التقدم المختلفة',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 30),

            // Circular Progress Examples
            _buildSectionTitle(context, 'المؤشرات الدائرية'),
            const SizedBox(height: 20),
            
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                ModernProgressChip(
                  percentage: 0.85,
                  label: 'الأداء العام',
                  subtitle: 'معدل إنجاز ممتاز',
                  icon: Icons.trending_up_rounded,
                  style: ProgressStyle.circular,
                  onTap: () => _showDetails(context, 'الأداء العام'),
                ),
                
                ModernProgressChip(
                  percentage: 0.65,
                  label: 'جودة البلاغات',
                  subtitle: 'مستوى جيد من الدقة',
                  icon: Icons.check_circle_outline,
                  style: ProgressStyle.circular,
                  size: const Size(300, 130),
                ),
                
                ModernProgressChip(
                  percentage: 0.40,
                  label: 'سرعة الاستجابة',
                  subtitle: 'يحتاج إلى تحسين',
                  icon: Icons.speed_rounded,
                  style: ProgressStyle.circular,
                ),
              ],
            ),
            
            const SizedBox(height: 40),

            // Linear Progress Examples
            _buildSectionTitle(context, 'المؤشرات الخطية'),
            const SizedBox(height: 20),
            
            Column(
              children: [
                ModernProgressChip(
                  percentage: 0.92,
                  label: 'معدل إكمال المهام',
                  subtitle: 'أداء استثنائي هذا الشهر',
                  icon: Icons.assignment_turned_in_rounded,
                  style: ProgressStyle.linear,
                  size: const Size(double.infinity, 160),
                  onTap: () => _showDetails(context, 'إكمال المهام'),
                ),
                
                const SizedBox(height: 20),
                
                ModernProgressChip(
                  percentage: 0.58,
                  label: 'رضا العملاء',
                  subtitle: 'تحسن مستمر في التقييمات',
                  icon: Icons.sentiment_satisfied_rounded,
                  style: ProgressStyle.linear,
                  size: const Size(double.infinity, 140),
                ),
              ],
            ),
            
            const SizedBox(height: 40),

            // Ring Progress Examples
            _buildSectionTitle(context, 'المؤشرات الحلقية'),
            const SizedBox(height: 20),
            
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                ModernProgressChip(
                  percentage: 0.78,
                  label: 'كفاءة الفريق',
                  subtitle: 'أداء متميز',
                  icon: Icons.group_rounded,
                  style: ProgressStyle.ring,
                ),
                
                ModernProgressChip(
                  percentage: 0.33,
                  label: 'الامتثال للمعايير',
                  subtitle: 'بحاجة لمراجعة',
                  icon: Icons.rule_rounded,
                  style: ProgressStyle.ring,
                  size: const Size(320, 140),
                ),
              ],
            ),
            
            const SizedBox(height: 40),

            // Gradient Progress Examples
            _buildSectionTitle(context, 'المؤشرات المتدرجة'),
            const SizedBox(height: 20),
            
            Column(
              children: [
                ModernProgressChip(
                  percentage: 0.88,
                  label: 'التقدم الشهري',
                  subtitle: 'مسار ممتاز نحو الهدف',
                  icon: Icons.calendar_month_rounded,
                  style: ProgressStyle.gradient,
                  size: const Size(double.infinity, 120),
                ),
                
                const SizedBox(height: 20),
                
                ModernProgressChip(
                  percentage: 0.45,
                  label: 'الابتكار والتطوير',
                  subtitle: 'فرص للنمو والتحسين',
                  icon: Icons.lightbulb_outline_rounded,
                  style: ProgressStyle.gradient,
                  size: const Size(double.infinity, 120),
                ),
              ],
            ),
            
            const SizedBox(height: 40),

            // Skeleton Progress Examples
            _buildSectionTitle(context, 'المؤشرات الهيكلية'),
            const SizedBox(height: 20),
            
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                ModernProgressChip(
                  percentage: 0.72,
                  label: 'تحليل البيانات',
                  subtitle: 'معالجة مستمرة',
                  icon: Icons.analytics_rounded,
                  style: ProgressStyle.skeleton,
                ),
                
                ModernProgressChip(
                  percentage: 0.95,
                  label: 'نسخ احتياطي',
                  subtitle: 'مكتمل تقريباً',
                  icon: Icons.backup_rounded,
                  style: ProgressStyle.skeleton,
                  size: const Size(300, 130),
                ),
              ],
            ),
            
            const SizedBox(height: 40),

            // Performance Comparison Section
            _buildSectionTitle(context, 'مقارنة الأداء'),
            const SizedBox(height: 20),
            
            _buildPerformanceComparison(),
            
            const SizedBox(height: 40),

            // Tips Section
            _buildTipsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildPerformanceComparison() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ModernProgressChip(
                percentage: 0.85,
                label: 'هذا الشهر',
                subtitle: 'الأداء الحالي',
                icon: Icons.trending_up,
                style: ProgressStyle.circular,
                size: const Size(200, 120),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ModernProgressChip(
                percentage: 0.72,
                label: 'الشهر الماضي',
                subtitle: 'للمقارنة',
                icon: Icons.history,
                style: ProgressStyle.circular,
                size: const Size(200, 120),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF10B981).withOpacity(0.1),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'تحسن بنسبة 13% مقارنة بالشهر الماضي',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    final tips = [
      {
        'icon': Icons.palette_rounded,
        'title': 'التصميم المتجاوب',
        'description': 'استخدم أحجام مختلفة حسب المحتوى',
      },
      {
        'icon': Icons.animation_rounded,
        'title': 'الحركة والتفاعل',
        'description': 'إضافة تأثيرات بصرية عند التمرير',
      },
      {
        'icon': Icons.accessibility_rounded,
        'title': 'سهولة الوصول',
        'description': 'ألوان واضحة ونصوص مقروءة',
      },
      {
        'icon': Icons.psychology_rounded,
        'title': 'تجربة المستخدم',
        'description': 'معلومات واضحة ومفيدة',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'نصائح التصميم'),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: tips.length,
          itemBuilder: (context, index) {
            final tip = tips[index];
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                  ],
                ),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      tip['icon'] as IconData,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tip['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tip['description'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل $title'),
        content: const Text('هنا يمكن عرض المزيد من التفاصيل والإحصائيات المتقدمة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

/// Widget for demonstrating different progress states
class ProgressShowcase extends StatefulWidget {
  const ProgressShowcase({super.key});

  @override
  State<ProgressShowcase> createState() => _ProgressShowcaseState();
}

class _ProgressShowcaseState extends State<ProgressShowcase>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _controller.addListener(() {
      setState(() {
        _currentProgress = _controller.value;
      });
    });
    
    _startAnimation();
  }

  void _startAnimation() {
    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _controller.reset();
          _startAnimation();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'عرض تقدمي متحرك',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        ModernProgressChip(
          percentage: _currentProgress,
          label: 'تقدم مباشر',
          subtitle: 'مؤشر متحرك تلقائياً',
          icon: Icons.play_circle_rounded,
          style: ProgressStyle.circular,
          size: const Size(300, 140),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => _controller.forward(),
              child: const Text('تشغيل'),
            ),
            ElevatedButton(
              onPressed: () => _controller.stop(),
              child: const Text('إيقاف'),
            ),
            ElevatedButton(
              onPressed: () => _controller.reset(),
              child: const Text('إعادة تعيين'),
            ),
          ],
        ),
      ],
    );
  }
} 