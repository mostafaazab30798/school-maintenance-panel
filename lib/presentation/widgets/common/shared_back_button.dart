import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A shared back button widget that works consistently across all screens
class SharedBackButton extends StatelessWidget {
  final Color? color;
  final double? size;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool forceShow;

  const SharedBackButton({
    super.key,
    this.color,
    this.size,
    this.tooltip,
    this.onPressed,
    this.forceShow = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we can go back using GoRouter or Navigator
    final canGoBack =
        GoRouter.of(context).canPop() || Navigator.canPop(context);

    // Only show if we can go back or forceShow is true
    if (!canGoBack && !forceShow) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: color ?? Theme.of(context).appBarTheme.iconTheme?.color,
        size: size ?? 24,
      ),
      tooltip: tooltip ?? 'الرجوع',
      onPressed: onPressed ?? () => _handleBackPress(context),
    );
  }

  void _handleBackPress(BuildContext context) {
    // Try GoRouter first, then fallback to Navigator
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Last resort - navigate to home
      context.go('/');
    }
  }
}

/// A floating back button for screens that don't use app bars
class FloatingBackButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onPressed;

  const FloatingBackButton({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SharedBackButton(
          color: iconColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
          onPressed: onPressed,
          forceShow: true,
        ),
      ),
    );
  }
}
