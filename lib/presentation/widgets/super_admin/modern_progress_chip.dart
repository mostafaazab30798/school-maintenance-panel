import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class ModernProgressChip extends StatefulWidget {
  final double percentage;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showBackground;
  final Size? size;
  final ProgressStyle style;

  const ModernProgressChip({
    super.key,
    required this.percentage,
    required this.label,
    this.subtitle,
    this.icon,
    this.onTap,
    this.showBackground = true,
    this.size,
    this.style = ProgressStyle.circular,
  });

  @override
  State<ModernProgressChip> createState() => _ModernProgressChipState();
}

enum ProgressStyle {
  circular,
  linear,
  ring,
  gradient,
  skeleton,
}

class _ModernProgressChipState extends State<ModernProgressChip>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Hover animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Pulse animation for emphasis
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Progress animation with easing
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.percentage.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // Scale animation for hover effect
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    // Glow animation for progress completion
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Color animation based on progress
    _colorAnimation = ColorTween(
      begin: _getProgressColor(0.0),
      end: _getProgressColor(widget.percentage),
    ).animate(_progressAnimation);
  }

  void _startAnimations() {
    // Start progress animation with delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _progressController.forward();
      }
    });

    // Start pulse animation if progress is complete
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.percentage >= 0.9) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return const Color(0xFF10B981); // Emerald - Excellent
    if (progress >= 0.7) return const Color(0xFF3B82F6); // Blue - Good  
    if (progress >= 0.5) return const Color(0xFF8B5CF6); // Purple - Average
    if (progress >= 0.3) return const Color(0xFFF59E0B); // Amber - Below Average
    return const Color(0xFFEF4444); // Red - Poor
  }

  IconData _getProgressIcon(double progress) {
    if (progress >= 0.9) return Icons.stars_rounded;
    if (progress >= 0.7) return Icons.trending_up_rounded;
    if (progress >= 0.5) return Icons.show_chart_rounded;
    if (progress >= 0.3) return Icons.trending_flat_rounded;
    return Icons.trending_down_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _progressAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildChipContent(context, isDark),
            );
          },
        ),
      ),
    );
  }

  void _onHoverChange(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  Widget _buildChipContent(BuildContext context, bool isDark) {
    final currentColor = _colorAnimation.value ?? _getProgressColor(widget.percentage);
    
    return Container(
      width: widget.size?.width ?? 320,
      height: widget.size?.height ?? 140,
      decoration: _buildContainerDecoration(isDark, currentColor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background gradient overlay
            if (widget.showBackground) _buildBackgroundGradient(isDark),
            
            // Glass morphism layer
            _buildGlassMorphismLayer(isDark),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildContentByStyle(context, isDark, currentColor),
            ),
            
            // Animated border glow
            if (_isHovered || widget.percentage >= 0.9)
              _buildAnimatedBorder(currentColor),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(bool isDark, Color currentColor) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF1E293B).withOpacity(0.95),
                const Color(0xFF0F172A).withOpacity(0.95),
              ]
            : [
                Colors.white.withOpacity(0.95),
                const Color(0xFFF8FAFC).withOpacity(0.95),
              ],
      ),
      border: Border.all(
        color: _isHovered
            ? currentColor.withOpacity(0.4)
            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
        width: 2,
      ),
      boxShadow: [
        // Primary shadow with color
        BoxShadow(
          color: currentColor.withOpacity(_isHovered ? 0.2 : 0.1),
          blurRadius: _isHovered ? 25 : 15,
          offset: const Offset(0, 10),
          spreadRadius: _isHovered ? 3 : 1,
        ),
        // Secondary depth shadow
        BoxShadow(
          color: (isDark ? Colors.black : Colors.grey.shade400)
              .withOpacity(_isHovered ? 0.4 : 0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
        // Inner highlight
        BoxShadow(
          color: Colors.white.withOpacity(isDark ? 0.1 : 0.7),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildBackgroundGradient(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.8,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.08),
                  Colors.transparent,
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  Colors.transparent,
                ],
        ),
      ),
    );
  }

  Widget _buildGlassMorphismLayer(bool isDark) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.06),
                  ]
                : [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.4),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentByStyle(BuildContext context, bool isDark, Color currentColor) {
    switch (widget.style) {
      case ProgressStyle.circular:
        return _buildCircularContent(context, isDark, currentColor);
      case ProgressStyle.linear:
        return _buildLinearContent(context, isDark, currentColor);
      case ProgressStyle.ring:
        return _buildRingContent(context, isDark, currentColor);
      case ProgressStyle.gradient:
        return _buildGradientContent(context, isDark, currentColor);
      case ProgressStyle.skeleton:
        return _buildSkeletonContent(context, isDark, currentColor);
    }
  }

  Widget _buildCircularContent(BuildContext context, bool isDark, Color currentColor) {
    return Row(
      children: [
        // Modern Circular Progress Indicator
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle with gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentColor.withOpacity(0.15),
                    currentColor.withOpacity(0.08),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            // Animated progress circle
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: ModernCircularProgressPainter(
                  progress: _progressAnimation.value,
                  color: currentColor,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                  strokeWidth: 7,
                  glowIntensity: _glowAnimation.value,
                ),
              ),
            ),
            // Center icon and percentage
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Icon(
                    widget.icon ?? _getProgressIcon(widget.percentage),
                    key: ValueKey(widget.percentage >= 0.9),
                    color: currentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: currentColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(width: 24),
        
        // Content section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Modern quality indicator
              _buildQualityIndicator(currentColor, isDark),
            ],
          ),
        ),
        
        // Navigation indicator
        if (widget.onTap != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  currentColor.withOpacity(0.2),
                  currentColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: currentColor,
              size: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildLinearContent(BuildContext context, bool isDark, Color currentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    currentColor.withOpacity(0.2),
                    currentColor.withOpacity(0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                widget.icon ?? _getProgressIcon(widget.percentage),
                color: currentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: currentColor.withOpacity(0.1),
              ),
              child: Text(
                '${(_progressAnimation.value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: currentColor,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Segmented progress bar
        _buildSegmentedProgressBar(currentColor, isDark),
        
        const SizedBox(height: 12),
        
        // Quality indicator
        _buildQualityIndicator(currentColor, isDark),
      ],
    );
  }

  Widget _buildRingContent(BuildContext context, bool isDark, Color currentColor) {
    return Row(
      children: [
        // Ring progress with enhanced styling
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentColor.withOpacity(0.15),
                    currentColor.withOpacity(0.05),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(
                painter: ModernRingProgressPainter(
                  progress: _progressAnimation.value,
                  color: currentColor,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                  strokeWidth: 8,
                  glowIntensity: _glowAnimation.value,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon ?? _getProgressIcon(widget.percentage),
                  color: currentColor,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: currentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(width: 24),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildQualityIndicator(currentColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientContent(BuildContext context, bool isDark, Color currentColor) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    currentColor.withOpacity(0.2),
                    currentColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                widget.icon ?? _getProgressIcon(widget.percentage),
                color: currentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Text(
              '${(_progressAnimation.value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: currentColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Gradient progress bar
        Container(
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(currentColor),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        _buildQualityIndicator(currentColor, isDark),
      ],
    );
  }

  Widget _buildSkeletonContent(BuildContext context, bool isDark, Color currentColor) {
    return Row(
      children: [
        // Skeleton-style indicator
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                currentColor.withOpacity(0.3),
                currentColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            widget.icon ?? _getProgressIcon(widget.percentage),
            color: currentColor,
            size: 28,
          ),
        ),
        
        const SizedBox(width: 20),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with skeleton effect
              Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      currentColor.withOpacity(0.3),
                      currentColor.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: currentColor,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Progress skeleton
              _buildSkeletonProgressBar(currentColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQualityIndicator(Color currentColor, bool isDark) {
    String qualityText;
    IconData qualityIcon;
    
    if (widget.percentage >= 0.9) {
      qualityText = 'ممتاز';
      qualityIcon = Icons.star_rounded;
    } else if (widget.percentage >= 0.7) {
      qualityText = 'جيد جداً';
      qualityIcon = Icons.thumb_up_rounded;
    } else if (widget.percentage >= 0.5) {
      qualityText = 'جيد';
      qualityIcon = Icons.check_circle_rounded;
    } else if (widget.percentage >= 0.3) {
      qualityText = 'مقبول';
      qualityIcon = Icons.info_rounded;
    } else {
      qualityText = 'يحتاج تحسين';
      qualityIcon = Icons.warning_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            currentColor.withOpacity(0.15),
            currentColor.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: currentColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: currentColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            qualityIcon,
            size: 16,
            color: currentColor,
          ),
          const SizedBox(width: 6),
          Text(
            qualityText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: currentColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedProgressBar(Color currentColor, bool isDark) {
    const segments = 12;
    final filledSegments = (_progressAnimation.value * segments).round();
    
    return Row(
      children: List.generate(segments, (index) {
        final isFilled = index < filledSegments;
        final isLast = index == segments - 1;
        
        return Expanded(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            height: 10,
            margin: EdgeInsets.only(right: isLast ? 0 : 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isFilled
                  ? currentColor
                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
              boxShadow: isFilled ? [
                BoxShadow(
                  color: currentColor.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSkeletonProgressBar(Color currentColor) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          colors: [
            currentColor.withOpacity(0.3),
            currentColor.withOpacity(0.1),
            currentColor.withOpacity(0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: _progressAnimation.value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(currentColor.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildAnimatedBorder(Color currentColor) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: currentColor.withOpacity(0.4 + (_glowAnimation.value * 0.4)),
            width: 3,
          ),
        ),
      ),
    );
  }
}

// Enhanced Custom Painters
class ModernCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double glowIntensity;

  ModernCircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc with enhanced glow
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Enhanced glow effect
      if (glowIntensity > 0) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.4 * glowIntensity)
          ..strokeWidth = strokeWidth + 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * progress,
          false,
          glowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
      
      // Add progress end indicator
      if (progress < 1.0) {
        final endAngle = -math.pi / 2 + (2 * math.pi * progress);
        final endX = center.dx + radius * math.cos(endAngle);
        final endY = center.dy + radius * math.sin(endAngle);
        
        final endPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(Offset(endX, endY), strokeWidth / 2, endPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ModernCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

// Enhanced Ring Progress Painter
class ModernRingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double glowIntensity;

  ModernRingProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring with enhanced effects
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Enhanced glow for high completion
      if (glowIntensity > 0 && progress >= 0.8) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.5 * glowIntensity)
          ..strokeWidth = strokeWidth + 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * progress,
          false,
          glowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ModernRingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowIntensity != glowIntensity;
  }
} 