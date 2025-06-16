import 'package:flutter/material.dart';

/// Reusable error widget with consistent styling and retry functionality
///
/// This widget provides a standardized error display that can be used
/// throughout the application for consistent error handling.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final String? retryButtonText;
  final bool showRetryButton;

  const AppErrorWidget({
    Key? key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.retryButtonText,
    this.showRetryButton = true,
  }) : super(key: key);

  /// Creates a network error widget with appropriate messaging
  const AppErrorWidget.network({
    Key? key,
    this.message =
        'Unable to connect to the server. Please check your internet connection.',
    this.title = 'Connection Error',
    this.onRetry,
    this.retryButtonText,
    this.showRetryButton = true,
  })  : icon = Icons.wifi_off,
        super(key: key);

  /// Creates an access denied error widget
  const AppErrorWidget.accessDenied({
    Key? key,
    this.message = 'You do not have permission to access this data.',
    this.title = 'Access Denied',
    this.onRetry,
    this.retryButtonText,
    this.showRetryButton = false,
  })  : icon = Icons.lock,
        super(key: key);

  /// Creates a not found error widget
  const AppErrorWidget.notFound({
    Key? key,
    this.message = 'The requested data could not be found.',
    this.title = 'Not Found',
    this.onRetry,
    this.retryButtonText,
    this.showRetryButton = true,
  })  : icon = Icons.search_off,
        super(key: key);

  /// Creates a generic server error widget
  const AppErrorWidget.server({
    Key? key,
    this.message = 'Something went wrong on our end. Please try again later.',
    this.title = 'Server Error',
    this.onRetry,
    this.retryButtonText,
    this.showRetryButton = true,
  })  : icon = Icons.error_outline,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveIcon = icon ?? Icons.error_outline;
    final effectiveTitle = title ?? 'Error';
    final effectiveRetryText = retryButtonText ?? 'Try Again';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              effectiveIcon,
              size: 64,
              color: isDark ? Colors.red[300] : Colors.red[600],
            ),
            const SizedBox(height: 16),
            Text(
              effectiveTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.red[300] : Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(effectiveRetryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact error widget for inline use
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const InlineErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.showRetryButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.red[900]?.withOpacity(0.3) : Colors.red[50],
        border: Border.all(
          color: isDark ? Colors.red[300]! : Colors.red[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: isDark ? Colors.red[300] : Colors.red[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.red[300] : Colors.red[700],
              ),
            ),
          ),
          if (showRetryButton && onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: isDark ? Colors.red[300] : Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error widget specifically for list items
class ListErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ListErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AppErrorWidget(
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

/// Snackbar helper for showing error messages
class ErrorSnackBar {
  static void show(BuildContext context, String message,
      {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    show(
      context,
      'Network error. Please check your connection.',
      onRetry: onRetry,
    );
  }

  static void showAccessDenied(BuildContext context) {
    show(context, 'Access denied. You do not have permission.');
  }

  static void showServerError(BuildContext context, {VoidCallback? onRetry}) {
    show(
      context,
      'Server error. Please try again later.',
      onRetry: onRetry,
    );
  }
}
