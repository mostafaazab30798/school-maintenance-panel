/// Utilities for formatting dates, numbers, and other common data display patterns
class FormatUtils {
  
  /// Format date string to display format (dd-MM-yyyy)
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Format date for supervisor display
  static String formatSupervisorDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Format completion percentage to display with proper rounding
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(0)}%';
  }

  /// Format large numbers with thousands separator if needed
  static String formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Get readable time ago format
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime.toIso8601String());
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  /// Format email to display format (truncate if too long)
  static String formatEmail(String email, {int maxLength = 25}) {
    if (email.length <= maxLength) {
      return email;
    }
    return '${email.substring(0, maxLength - 3)}...';
  }

  /// Format username to display format
  static String formatUsername(String? username) {
    return username?.isNotEmpty == true ? username! : 'غير محدد';
  }

  /// Get proper Arabic plural form for numbers
  static String getArabicPlural(int count, String singular, String plural, String pluralOfTen) {
    if (count == 1) {
      return singular;
    } else if (count == 2) {
      return plural;
    } else if (count >= 3 && count <= 10) {
      return pluralOfTen;
    } else {
      return pluralOfTen;
    }
  }

  /// Format report status to Arabic
  static String formatReportStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'في الانتظار';
      case 'completed':
        return 'مكتمل';
      case 'late':
        return 'متأخر';
      case 'assigned':
        return 'مُعيّن';
      case 'unassigned':
        return 'غير مُعيّن';
      default:
        return status;
    }
  }

  /// Get completion rate description in Arabic
  static String getCompletionRateDescription(double rate) {
    if (rate >= 90) {
      return 'ممتاز';
    } else if (rate >= 80) {
      return 'جيد جداً';
    } else if (rate >= 70) {
      return 'جيد';
    } else if (rate >= 60) {
      return 'متوسط';
    } else if (rate >= 50) {
      return 'ضعيف';
    } else {
      return 'ضعيف جداً';
    }
  }

  /// Format duration in Arabic
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${getArabicPlural(duration.inDays, 'يوم', 'يومان', 'أيام')}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${getArabicPlural(duration.inHours, 'ساعة', 'ساعتان', 'ساعات')}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${getArabicPlural(duration.inMinutes, 'دقيقة', 'دقيقتان', 'دقائق')}';
    } else {
      return 'أقل من دقيقة';
    }
  }
} 