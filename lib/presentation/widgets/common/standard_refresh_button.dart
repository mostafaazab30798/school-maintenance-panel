import 'package:flutter/material.dart';

class StandardRefreshButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;
  final bool isLoading;
  final double? size;

  const StandardRefreshButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'تحديث البيانات',
    this.isLoading = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF3B82F6),
                  ),
                ),
              )
            : const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF3B82F6),
              ),
        tooltip: tooltip,
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}

class StandardRefreshElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isLoading;

  const StandardRefreshElevatedButton({
    super.key,
    required this.onPressed,
    this.label = 'إعادة المحاولة',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.refresh_rounded),
      label: Text(isLoading ? 'جاري التحديث...' : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }
}
