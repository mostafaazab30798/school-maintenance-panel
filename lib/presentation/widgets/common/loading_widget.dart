import 'package:flutter/material.dart';

/// Reusable loading widget with consistent styling across the app
///
/// This widget provides a standardized loading indicator that can be used
/// in various contexts throughout the application.
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final bool showMessage;

  const LoadingWidget({
    Key? key,
    this.message,
    this.size,
    this.color,
    this.showMessage = true,
  }) : super(key: key);

  /// Creates a small loading widget for inline use
  const LoadingWidget.small({
    Key? key,
    this.message,
    this.color,
    this.showMessage = false,
  })  : size = 16.0,
        super(key: key);

  /// Creates a large loading widget for full-screen use
  const LoadingWidget.large({
    Key? key,
    this.message,
    this.color,
    this.showMessage = true,
  })  : size = 48.0,
        super(key: key);

  /// Creates a loading widget for cards and containers
  const LoadingWidget.card({
    Key? key,
    this.message,
    this.color,
    this.showMessage = true,
  })  : size = 32.0,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveColor =
        color ?? (isDark ? Colors.white70 : theme.primaryColor);

    final effectiveSize = size ?? 24.0;

    final defaultMessage = message ?? 'Loading...';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: effectiveSize,
            height: effectiveSize,
            child: CircularProgressIndicator(
              strokeWidth: effectiveSize > 32 ? 4.0 : 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              defaultMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: effectiveColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading widget specifically designed for list items
class ListLoadingWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListLoadingWidget({
    Key? key,
    this.itemCount = 3,
    this.itemHeight = 80.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: LoadingWidget.small(),
          ),
        );
      },
    );
  }
}

/// Shimmer loading effect for better user experience
class ShimmerLoadingWidget extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoadingWidget({
    Key? key,
    required this.child,
    this.isLoading = true,
  }) : super(key: key);

  @override
  State<ShimmerLoadingWidget> createState() => _ShimmerLoadingWidgetState();
}

class _ShimmerLoadingWidgetState extends State<ShimmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                isDark ? Colors.grey[800]! : Colors.grey[300]!,
                isDark ? Colors.grey[600]! : Colors.grey[100]!,
                isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
