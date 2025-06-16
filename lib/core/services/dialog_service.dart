import 'package:flutter/material.dart';
import '../../presentation/widgets/common/esc_dismissible_dialog.dart';

/// Service for handling common dialog operations
class DialogService {
  /// Show a progress details dialog
  static void showProgressDetails(
    BuildContext context, {
    required String title,
    required int totalWork,
    required int completedWork,
    required double completionRate,
  }) {
    context.showEscDismissibleDialog(
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressDetailRow('إجمالي المهام', totalWork.toString()),
            _buildProgressDetailRow('المهام المكتملة', completedWork.toString()),
            _buildProgressDetailRow('المهام المتبقية', (totalWork - completedWork).toString()),
            const Divider(),
            _buildProgressDetailRow('معدل الإنجاز', '${completionRate.toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// Build a progress detail row
  static Widget _buildProgressDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Show a generic alert dialog
  static void showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    context.showEscDismissibleDialog(
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          if (actionText != null && onAction != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionText),
            ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show a loading dialog
  static void showLoading(
    BuildContext context, {
    String message = 'جاري التحميل...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show an error dialog
  static void showError(
    BuildContext context, {
    required String message,
    String title = 'خطأ',
  }) {
    showAlert(
      context,
      title: title,
      message: message,
    );
  }

  /// Show a success dialog
  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'نجح',
  }) {
    showAlert(
      context,
      title: title,
      message: message,
    );
  }
} 