import 'package:flutter/material.dart';
import 'dart:ui';

class CompletionProgressCard extends StatefulWidget {
  final double percentage;
  final VoidCallback? onTap;

  const CompletionProgressCard({
    super.key,
    required this.percentage,
    this.onTap,
  });

  @override
  State<CompletionProgressCard> createState() => _CompletionProgressCardState();
}

class _CompletionProgressCardState extends State<CompletionProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _hoverController; // Separate controller for hover effects
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation; // Add glow animation for hover effect
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Separate hover controller for scale effects
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.percentage.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0, // Remove scaling completely - use 1.0 for both begin and end
    ).animate(CurvedAnimation(
      parent: _hoverController, // Use separate hover controller
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.6, // Glow effect: 1.0 to 1.6
    ).animate(CurvedAnimation(
      parent: _hoverController, // Use separate hover controller
      curve: Curves.easeInOut,
    ));

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hoverController.dispose(); // Dispose hover controller
    super.dispose();
  }

  @override
  void didUpdateWidget(CompletionProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the percentage has changed, update the animation
    if (oldWidget.percentage != widget.percentage) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    _animationController.reset(); // Only reset progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.percentage.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  Color _getProgressColor(double percent) {
    if (percent >= 0.81) return const Color(0xFF10B981); // Green - Excellent
    if (percent >= 0.61) return const Color(0xFF3B82F6); // Blue - Good
    if (percent >= 0.51) return const Color(0xFFF59E0B); // Orange - Average
    return const Color(0xFFEF4444); // Red - Bad
  }

  IconData _getProgressIcon(double percent) {
    if (percent >= 0.81) return Icons.trending_up_rounded; // Excellent
    if (percent >= 0.61) return Icons.trending_up_rounded; // Good
    if (percent >= 0.51) return Icons.trending_flat_rounded; // Average
    return Icons.trending_down_rounded; // Bad
  }

  String _getProgressLabel(double percent) {
    if (percent >= 0.81) return 'ممتاز';
    if (percent >= 0.61) return 'جيد';
    if (percent >= 0.51) return 'متوسط';
    return 'يحتاج تحسين';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.white;

    final color = _getProgressColor(widget.percentage);
    final icon = _getProgressIcon(widget.percentage);
    final label = _getProgressLabel(widget.percentage);
    final percentText = '${(widget.percentage * 100).toStringAsFixed(1)}%';

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _glowAnimation]), // Listen to both animations
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardColor.withOpacity(0.9),
                      cardColor.withOpacity(0.7),
                    ],
                  ),
                  border: Border.all(
                    color: _isHovered
                        ? color.withOpacity(0.3)
                        : borderColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(_isHovered ? 0.25 * _glowAnimation.value : 0.08), // Enhanced glow
                      blurRadius: _isHovered ? 20 * _glowAnimation.value : 10, // Dynamic blur
                      offset: const Offset(0, 6),
                      spreadRadius: _isHovered ? 2 : 0, // Spread for glow effect
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.8),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF334155).withOpacity(0.25),
                                  const Color(0xFF334155).withOpacity(0.1),
                                ]
                              : [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.1),
                                ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      color.withOpacity(0.2),
                                      color.withOpacity(0.1),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: color.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: color,
                                  size: 18,
                                ),
                              ),
                              // Progress indicator in top right corner
                              SizedBox(
                                height: 36,
                                width: 36,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _progressAnimation,
                                      builder: (context, child) {
                                        return CircularProgressIndicator(
                                          value: _progressAnimation.value,
                                          backgroundColor: color.withOpacity(0.2),
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                          strokeWidth: 3.0,
                                          strokeCap: StrokeCap.round,
                                        );
                                      },
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(
                                        Icons.arrow_outward_rounded,
                                        color: color.withOpacity(_isHovered ? 1.0 : 0.6),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Text(
                                percentText,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFFF1F5F9)
                                          : const Color(0xFF1E293B),
                                      letterSpacing: -0.6,
                                      height: 1.1,
                                    ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'معدل الإنجاز',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
