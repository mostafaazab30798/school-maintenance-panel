import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../../core/services/excel_report_service.dart';
import '../../../data/models/excel_report_data.dart';

class ExcelUploadWidget extends StatefulWidget {
  final Function(Map<String, List<ExcelReportData>>) onExcelProcessed;
  final String? errorMessage;
  final bool isLoading;

  const ExcelUploadWidget({
    super.key,
    required this.onExcelProcessed,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  State<ExcelUploadWidget> createState() => _ExcelUploadWidgetState();
}

class _ExcelUploadWidgetState extends State<ExcelUploadWidget> {
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.2),
                      const Color(0xFF10B981).withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رفع ملف الإكسل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'قم برفع ملف الإكسل لاستخراج البلاغات تلقائياً',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Error message
          if (_errorMessage != null || widget.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFEF4444).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage ?? widget.errorMessage ?? '',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Success message
          if (_successMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF10B981).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Upload button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_isProcessing || widget.isLoading) ? null : _pickExcelFile,
              icon: _isProcessing || widget.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.file_upload_rounded, size: 18),
              label: Text(
                _isProcessing || widget.isLoading
                    ? 'جاري المعالجة...'
                    : 'اختر ملف الإكسل',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExcelFile() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
        _successMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        print('📁 Selected file: ${file.name}, size: ${file.size} bytes');
        
        // Check file extension
        if (!file.name.toLowerCase().endsWith('.xlsx') && !file.name.toLowerCase().endsWith('.xls')) {
          setState(() {
            _errorMessage = 'يرجى اختيار ملف إكسل صحيح (.xlsx أو .xls)';
            _isProcessing = false;
          });
          return;
        }
        
        // Process Excel file
        final excelService = ExcelReportService();
        
        // Validate file structure first
        print('🔍 Validating Excel file structure...');
        if (!excelService.validateExcelStructure(file.bytes!)) {
          setState(() {
            _errorMessage = 'تنسيق الملف غير صحيح. تأكد من أن الملف يحتوي على الأعمدة المطلوبة (E, G, H, K, M, O).\n\n💡 نصائح لحل المشكلة:\n• تأكد من حفظ الملف بصيغة .xlsx من Excel\n• لا تحفظ من المتصفح أو برامج أخرى\n• تأكد من أن الملف غير تالف';
            _isProcessing = false;
          });
          return;
        }
        
        print('✅ File structure validation passed, parsing data...');
        final reports = await excelService.parseExcelFile(file.bytes!);
        
        if (reports.isEmpty) {
          setState(() {
            _errorMessage = 'لم يتم العثور على بلاغات بحالة "In_Progress" في الملف. تأكد من أن العمود K يحتوي على "In_Progress".';
            _isProcessing = false;
          });
          return;
        }
        
        // Group by school
        final reportsBySchool = await excelService.groupReportsBySchool(reports);
        
        // Calculate statistics
        final totalReports = reports.length;
        final totalSchools = reportsBySchool.length;
        
        print('✅ Successfully processed $totalReports reports from $totalSchools schools');
        
        setState(() {
          _successMessage = 'تم رفع $totalReports بلاغ من $totalSchools مدرسة بنجاح';
          _isProcessing = false;
        });
        
        // Call the callback with processed data
        widget.onExcelProcessed(reportsBySchool);
        
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('❌ Error in Excel upload: $e');
      
      String errorMessage = 'خطأ في رفع الملف';
      
      // Provide specific error messages based on the exception
      if (e.toString().contains('XmlParserException')) {
        errorMessage = 'تنسيق الملف غير مدعوم. يرجى حفظ الملف بصيغة .xlsx\n\n💡 الحلول المقترحة:\n• افتح الملف في Excel واحفظه بصيغة .xlsx\n• تأكد من عدم حفظ الملف من المتصفح\n• تحقق من أن الملف غير تالف';
      } else if (e.toString().contains('Expected a single root element')) {
        errorMessage = 'الملف ليس ملف إكسل صحيح. تأكد من أنه ملف إكسل وليس HTML أو تنسيق آخر\n\n💡 الحلول المقترحة:\n• تأكد من أن الملف تم إنشاؤه في Excel\n• لا تحفظ من المتصفح أو برامج أخرى\n• احفظ الملف بصيغة .xlsx من Excel';
      } else if (e.toString().contains('zip')) {
        errorMessage = 'الملف قد يكون تالفاً. يرجى إعادة حفظ الملف\n\n💡 الحلول المقترحة:\n• افتح الملف في Excel واحفظه مرة أخرى\n• تحقق من اتصال الإنترنت عند التحميل\n• جرب تحميل الملف مرة أخرى';
      } else if (e.toString().contains('الملف فارغ')) {
        errorMessage = 'الملف فارغ أو لا يحتوي على بيانات\n\n💡 تأكد من أن الملف يحتوي على بيانات قبل الرفع';
      } else if (e.toString().contains('لم يتم العثور على جداول')) {
        errorMessage = 'لم يتم العثور على جداول في ملف الإكسل\n\n💡 تأكد من أن الملف يحتوي على جداول بيانات';
      } else if (e.toString().contains('حجم الملف صغير')) {
        errorMessage = 'حجم الملف صغير جداً. تأكد من أنه ملف إكسل صحيح\n\n💡 تأكد من أن الملف تم حفظه بشكل صحيح';
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _isProcessing = false;
      });
    }
  }
} 