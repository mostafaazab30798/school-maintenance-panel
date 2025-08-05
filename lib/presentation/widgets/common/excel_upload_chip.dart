import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../../core/services/excel_report_service.dart';
import '../../../data/models/excel_report_data.dart';

class ExcelUploadChip extends StatefulWidget {
  final Function(Map<String, List<ExcelReportData>>) onExcelProcessed;
  final String? errorMessage;
  final bool isLoading;

  const ExcelUploadChip({
    super.key,
    required this.onExcelProcessed,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  State<ExcelUploadChip> createState() => _ExcelUploadChipState();
}

class _ExcelUploadChipState extends State<ExcelUploadChip>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  late AnimationController _hoverController;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF10B981).withOpacity(0.1),
                const Color(0xFF059669).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.1 * _glowAnimation.value),
                blurRadius: 10 * _glowAnimation.value,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isProcessing ? null : _pickExcelFile,
              onHover: (hovered) {
                setState(() {
                  _isHovered = hovered;
                });
                if (hovered) {
                  _hoverController.forward();
                } else {
                  _hoverController.reverse();
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with background
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.upload_file_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Status text
                    if (_isProcessing)
                      Text(
                        'جاري المعالجة...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withOpacity(0.8)
                              : const Color(0xFF0F172A),
                        ),
                      )
                    else if (_successMessage != null)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'بيانات الإكسل جاهزة',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _successMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.7)
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                                                     Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(
                                 Icons.arrow_forward_rounded,
                                 color: const Color(0xFF10B981),
                                 size: 20,
                               ),
                               const SizedBox(width: 6),
                               Text(
                                 'إضافة البلاغات',
                                 style: TextStyle(
                                   color: const Color(0xFF10B981),
                                   fontSize: 14,
                                   fontWeight: FontWeight.w600,
                                 ),
                               ),
                             ],
                           ),
                        ],
                      )
                    else if (_errorMessage != null)
                      Column(
                        children: [
                          Text(
                            'خطأ في الرفع',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFEF4444).withOpacity(0.8),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Text(
                            'رفع ملف الإكسل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اضغط لرفع ملف الإكسل',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.bytes == null) {
          setState(() {
            _errorMessage = 'فشل في قراءة الملف. يرجى المحاولة مرة أخرى.';
            _isProcessing = false;
          });
          return;
        }

        final excelService = ExcelReportService();
        
        // Validate file structure
        final isValidStructure = await excelService.validateExcelStructure(file.bytes!);
        if (!isValidStructure) {
          setState(() {
            _errorMessage = 'تنسيق الملف غير صحيح. تأكد من أن الملف يحتوي على الأعمدة المطلوبة.';
            _isProcessing = false;
          });
          return;
        }
        
        // Parse data
        final reports = await excelService.parseExcelFile(file.bytes!);
        
        if (reports.isEmpty) {
          setState(() {
            _errorMessage = 'لم يتم العثور على بلاغات بحالة "In_Progress" في الملف.';
            _isProcessing = false;
          });
          return;
        }
        
        // Group by school
        final reportsBySchool = await excelService.groupReportsBySchool(reports);
        
        // Calculate statistics
        final totalReports = reports.length;
        final totalSchools = reportsBySchool.length;
        
        setState(() {
          _successMessage = 'تم رفع $totalReports بلاغ من $totalSchools مدرسة';
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
      
      if (e.toString().contains('XmlParserException')) {
        errorMessage = 'تنسيق الملف غير مدعوم. احفظ الملف بصيغة .xlsx';
      } else if (e.toString().contains('Expected a single root element')) {
        errorMessage = 'الملف ليس ملف إكسل صحيح';
      } else if (e.toString().contains('zip')) {
        errorMessage = 'الملف قد يكون تالفاً';
      } else if (e.toString().contains('الملف فارغ')) {
        errorMessage = 'الملف فارغ أو لا يحتوي على بيانات';
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _isProcessing = false;
      });
    }
  }
} 