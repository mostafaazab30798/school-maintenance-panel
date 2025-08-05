import 'dart:typed_data';
import '../services/excel_report_service.dart';

/// Utility class to validate Excel files before upload
class ExcelFileValidator {
  static final ExcelReportService _excelService = ExcelReportService();
  
  /// Validate Excel file and return detailed results
  static Future<ExcelValidationResult> validateFile(Uint8List fileBytes, String fileName) async {
    try {
      // Basic file checks
      if (fileBytes.isEmpty) {
        return ExcelValidationResult(
          isValid: false,
          error: 'الملف فارغ',
          suggestions: ['تأكد من أن الملف يحتوي على بيانات'],
        );
      }
      
      if (fileBytes.length < 100) {
        return ExcelValidationResult(
          isValid: false,
          error: 'حجم الملف صغير جداً',
          suggestions: [
            'تأكد من أن الملف تم حفظه بشكل صحيح',
            'جرب إعادة حفظ الملف في Excel',
          ],
        );
      }
      
      // Check file extension
      if (!fileName.toLowerCase().endsWith('.xlsx') && !fileName.toLowerCase().endsWith('.xls')) {
        return ExcelValidationResult(
          isValid: false,
          error: 'امتداد الملف غير صحيح',
          suggestions: [
            'يجب أن يكون امتداد الملف .xlsx أو .xls',
            'احفظ الملف بصيغة Excel',
          ],
        );
      }
      
      // Validate Excel structure
      if (!_excelService.validateExcelStructure(fileBytes)) {
        return ExcelValidationResult(
          isValid: false,
          error: 'تنسيق الملف غير صحيح',
          suggestions: [
            'تأكد من حفظ الملف بصيغة .xlsx من Excel',
            'لا تحفظ من المتصفح أو برامج أخرى',
            'تأكد من أن الملف غير تالف',
            'تحقق من وجود الأعمدة المطلوبة (E, G, H, K, M, O)',
          ],
        );
      }
      
      // Try to parse the file to check for data
      try {
        final reports = await _excelService.parseExcelFile(fileBytes);
        if (reports.isEmpty) {
          return ExcelValidationResult(
            isValid: false,
            error: 'لم يتم العثور على بلاغات بحالة "In_Progress"',
            suggestions: [
              'تأكد من وجود "In_Progress" في العمود K',
              'تحقق من أن البيانات تبدأ من الصف الثاني',
              'تأكد من وجود بيانات في الملف',
            ],
          );
        }
        
        return ExcelValidationResult(
          isValid: true,
          reportCount: reports.length,
          schoolCount: reports.map((r) => r.schoolName).toSet().length,
        );
        
      } catch (e) {
        return ExcelValidationResult(
          isValid: false,
          error: 'خطأ في قراءة بيانات الملف',
          suggestions: [
            'تأكد من أن الملف يحتوي على البيانات المطلوبة',
            'تحقق من تنسيق البيانات',
            'جرب إعادة حفظ الملف في Excel',
          ],
        );
      }
      
    } catch (e) {
      String error = 'خطأ غير معروف';
      List<String> suggestions = ['جرب إعادة تحميل الملف'];
      
      if (e.toString().contains('XmlParserException')) {
        error = 'تنسيق الملف غير مدعوم';
        suggestions = [
          'احفظ الملف بصيغة .xlsx من Excel',
          'تأكد من عدم حفظ الملف من المتصفح',
          'تحقق من أن الملف غير تالف',
        ];
      } else if (e.toString().contains('Expected a single root element')) {
        error = 'الملف ليس ملف إكسل صحيح';
        suggestions = [
          'تأكد من أن الملف تم إنشاؤه في Excel',
          'لا تحفظ من المتصفح أو برامج أخرى',
          'احفظ الملف بصيغة .xlsx من Excel',
        ];
      }
      
      return ExcelValidationResult(
        isValid: false,
        error: error,
        suggestions: suggestions,
      );
    }
  }
  
  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Check if file size is reasonable for Excel
  static bool isReasonableFileSize(int bytes) {
    return bytes >= 100 && bytes <= 50 * 1024 * 1024; // 100 bytes to 50 MB
  }
}

/// Result of Excel file validation
class ExcelValidationResult {
  final bool isValid;
  final String? error;
  final List<String> suggestions;
  final int? reportCount;
  final int? schoolCount;
  
  ExcelValidationResult({
    required this.isValid,
    this.error,
    this.suggestions = const [],
    this.reportCount,
    this.schoolCount,
  });
  
  /// Get success message if validation passed
  String? get successMessage {
    if (!isValid) return null;
    if (reportCount != null && schoolCount != null) {
      return 'تم العثور على $reportCount بلاغ من $schoolCount مدرسة';
    }
    return 'الملف صالح للرفع';
  }
} 