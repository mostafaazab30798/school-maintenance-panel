import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../../data/models/excel_report_data.dart';

class ExcelReportService {
  // Type mapping from Excel to system types
  static const Map<String, String> _typeMapping = {
    'أعمال مدنية': 'Civil',
    'السقف / الحائط على وشك الإنهيار': 'Civil',
    'تسريبات مياه من عناصر المبنى الإنشائية (أسقف - جدران - أرضيات)': 'Civil',
    'انقطاع كلي للمياه': 'Plumbing',
    'أعمال سباكة': 'Plumbing',
    'فيضان مياه': 'Plumbing',
    'انقطاع جزئي للمياه (دور كامل أو أكثر)': 'Plumbing',
    'أعمال المصاعدأعمال ميكانيكية': 'Plumbing',
    'أعمال في أنظمة مكافحة الحريق': 'Fire',
    'أعمال كهربائية': 'Electricity',
    'انقطاع جزئي للكهرباء (دور كامل أو أكثر)': 'Electricity',
    'انقطاع كلي للكهرباء': 'Electricity',
    'التماس كهربائي': 'Electricity',
    // HVAC category from M column
    'HVAC': 'AC',
  };
  
  // Priority mapping from Excel to system priorities (English)
  static const Map<String, String> _priorityMapping = {
    'روتيني': 'routine',
    'طارئ': 'emergency',
    'عاجل': 'emergency',
  };
  
  /// Parse Excel file and extract reports with In_Progress status
  Future<List<ExcelReportData>> parseExcelFile(Uint8List fileBytes) async {
    try {
      // Check file size first
      if (fileBytes.isEmpty) {
        throw Exception('الملف فارغ');
      }
      
      if (fileBytes.length < 100) {
        throw Exception('حجم الملف صغير جداً. تأكد من أنه ملف إكسل صحيح.');
      }
      
      // Try to decode Excel file with better error handling
      final excel = Excel.decodeBytes(fileBytes);
      
      if (excel.tables.isEmpty) {
        throw Exception('لم يتم العثور على جداول في ملف الإكسل');
      }
      
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet]!;
      
      print('📊 Excel file info: ${table.rows.length} rows, sheet: $sheet');
      
      if (table.rows.isEmpty) {
        throw Exception('الملف فارغ');
      }
      
      List<ExcelReportData> reports = [];
      int processedRows = 0;
      int skippedRows = 0;
      int inProgressRows = 0;
      
      // Skip header row (row 1) and process from row 2
      for (int row = 1; row < table.rows.length; row++) {
        final rowData = table.rows[row];
        processedRows++;
        
        // Skip empty rows
        if (rowData.isEmpty || rowData.every((cell) => cell?.value == null || cell!.value.toString().trim().isEmpty)) {
          skippedRows++;
          continue;
        }
        
        // Check if status is 'In_Progress' (column K - index 10)
        final status = rowData[10]?.value?.toString().trim() ?? '';
        if (status != 'In_Progress') {
          skippedRows++;
          continue;
        }
        
        inProgressRows++;
        
        // Extract data from specified columns
        final schoolName = rowData[4]?.value?.toString().trim() ?? ''; // E column (index 4)
        final description = rowData[6]?.value?.toString().trim() ?? ''; // G column (index 6)
        final excelType = rowData[7]?.value?.toString().trim() ?? ''; // H column (index 7)
        final excelPriority = rowData[14]?.value?.toString().trim() ?? ''; // O column (index 14)
        final mColumnValue = rowData[12]?.value?.toString().trim() ?? ''; // M column (index 12)
        final isHvacReport = mColumnValue.toUpperCase() == 'HVAC'; // Only treat as HVAC if M column contains exactly "HVAC"
        
        print('📋 Row ${row + 1}: School="$schoolName", Type="$excelType", Priority="$excelPriority", M_Column="$mColumnValue", HVAC=$isHvacReport');
        
        if (schoolName.isNotEmpty && description.isNotEmpty) {
          // Determine the type based on Excel type or HVAC status
          String finalType;
          if (isHvacReport) {
            finalType = 'AC'; // HVAC reports go to AC category
          } else {
            finalType = mapExcelTypeToSystemType(excelType);
          }
          
          reports.add(ExcelReportData(
            schoolName: schoolName,
            description: description,
            type: finalType,
            priority: mapExcelPriorityToSystemPriority(excelPriority),
            status: status,
            isHvacReport: isHvacReport,
          ));
        } else {
          print('⚠️ Row ${row + 1}: Skipped - missing school name or description');
        }
      }
      
      print('📊 Processing summary:');
      print('   - Total rows processed: $processedRows');
      print('   - Rows skipped (empty/not In_Progress): $skippedRows');
      print('   - In_Progress rows found: $inProgressRows');
      print('   - Valid reports created: ${reports.length}');
      
      return reports;
    } catch (e) {
      print('❌ Error parsing Excel file: $e');
      
      // Provide more specific error messages
      String errorMessage = 'خطأ في قراءة ملف الإكسل';
      
      if (e.toString().contains('XmlParserException')) {
        errorMessage = 'تنسيق الملف غير مدعوم. يرجى حفظ الملف بصيغة .xlsx';
      } else if (e.toString().contains('zip')) {
        errorMessage = 'الملف قد يكون تالفاً. يرجى إعادة حفظ الملف';
      } else if (e.toString().contains('Expected a single root element')) {
        errorMessage = 'الملف ليس ملف إكسل صحيح. تأكد من أنه ملف إكسل وليس HTML أو تنسيق آخر';
      } else if (e.toString().contains('الملف فارغ')) {
        errorMessage = 'الملف فارغ أو لا يحتوي على بيانات';
      } else if (e.toString().contains('لم يتم العثور على جداول')) {
        errorMessage = 'لم يتم العثور على جداول في ملف الإكسل';
      }
      
      throw Exception(errorMessage);
    }
  }
  
  /// Group reports by school name
  Future<Map<String, List<ExcelReportData>>> groupReportsBySchool(List<ExcelReportData> reports) async {
    final Map<String, List<ExcelReportData>> groupedReports = {};
    
    for (final report in reports) {
      groupedReports.putIfAbsent(report.schoolName, () => []).add(report);
    }
    
    return groupedReports;
  }
  
  /// Map Excel type to system type
  String mapExcelTypeToSystemType(String excelType) {
    return _typeMapping[excelType] ?? 'Civil'; // Default to Civil if not found
  }
  
  /// Map Excel priority to system priority
  String mapExcelPriorityToSystemPriority(String excelPriority) {
    return _priorityMapping[excelPriority] ?? 'routine'; // Default to routine if not found
  }
  
  /// Get all unique school names from Excel reports
  List<String> getSchoolNamesFromReports(List<ExcelReportData> reports) {
    final Set<String> schoolNames = {};
    for (final report in reports) {
      schoolNames.add(report.schoolName);
    }
    return schoolNames.toList()..sort();
  }
  
  /// Enhanced Excel file validation with better format detection
  bool validateExcelStructure(Uint8List fileBytes) {
    try {
      // Check if file is empty
      if (fileBytes.isEmpty) {
        print('❌ Excel file is empty');
        return false;
      }
      
      // Check file size (should be reasonable for Excel files)
      if (fileBytes.length < 100) {
        print('❌ Excel file too small (${fileBytes.length} bytes)');
        return false;
      }
      
      // Check for common file signatures to detect format issues
      if (_isHtmlFile(fileBytes)) {
        print('❌ File appears to be HTML, not Excel');
        print('💡 This might be a web page saved as .xlsx. Please export from Excel properly.');
        return false;
      }
      
      if (_isCsvFile(fileBytes)) {
        print('❌ File appears to be CSV, not Excel');
        print('💡 Please save as .xlsx format from Excel, not as CSV.');
        return false;
      }
      
      if (_isTextFile(fileBytes)) {
        print('❌ File appears to be plain text, not Excel');
        print('💡 Please ensure you\'re uploading a proper Excel file.');
        return false;
      }
      
      // Try to decode Excel file with better error handling
      final excel = Excel.decodeBytes(fileBytes);
      
      if (excel.tables.isEmpty) {
        print('❌ No tables found in Excel file');
        return false;
      }
      
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet]!;
      
      print('📊 Excel file info: ${table.rows.length} rows, sheet: $sheet');
      
      if (table.rows.isEmpty) {
        print('❌ No rows found in Excel file');
        return false;
      }
      
      // Check if we have at least one data row (skip header)
      if (table.rows.length < 2) {
        print('❌ Not enough rows in Excel file (need at least 2, found ${table.rows.length})');
        return false;
      }
      
      // Check if the first data row has enough columns for our required indices
      final firstDataRow = table.rows[1]; // Row 2 (index 1)
      
      print('📊 First data row has ${firstDataRow.length} columns');
      
      // We need columns at indices: 4 (E), 6 (G), 7 (H), 10 (K), 12 (M), 14 (O)
      final requiredIndices = [4, 6, 7, 10, 12, 14];
      
      for (final index in requiredIndices) {
        if (index >= firstDataRow.length) {
          print('❌ Missing required column at index $index. Row has ${firstDataRow.length} columns.');
          print('📋 Required columns: E(4), G(6), H(7), K(10), M(12), O(14)');
          return false;
        }
      }
      
      print('✅ Excel file structure validation passed. Found ${firstDataRow.length} columns.');
      return true;
    } catch (e) {
      print('❌ Excel file validation error: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('XmlParserException')) {
        print('💡 This might be an unsupported Excel format. Try saving as .xlsx format.');
        print('💡 Common causes:');
        print('   - File is actually HTML/CSV with .xlsx extension');
        print('   - File was saved from a web browser instead of Excel');
        print('   - File is corrupted or incomplete');
        print('   - File is in old .xls format (try .xlsx)');
      } else if (e.toString().contains('zip')) {
        print('💡 This might be a corrupted Excel file. Try re-saving the file.');
      } else if (e.toString().contains('Expected a single root element')) {
        print('💡 This might be an HTML file or unsupported format. Ensure it\'s a proper Excel file.');
        print('💡 Try opening the file in Excel and saving it as .xlsx format.');
      }
      
      return false;
    }
  }
  
  /// Check if file is actually HTML
  bool _isHtmlFile(Uint8List bytes) {
    if (bytes.length < 10) return false;
    
    // Check for HTML doctype or common HTML tags
    final start = String.fromCharCodes(bytes.take(100));
    return start.toLowerCase().contains('<!doctype') || 
           start.toLowerCase().contains('<html') ||
           start.toLowerCase().contains('<head') ||
           start.toLowerCase().contains('<body');
  }
  
  /// Check if file is actually CSV
  bool _isCsvFile(Uint8List bytes) {
    if (bytes.length < 10) return false;
    
    // Check for CSV patterns (comma-separated values)
    final content = String.fromCharCodes(bytes.take(1000));
    final lines = content.split('\n');
    
    if (lines.length < 2) return false;
    
    // Check if first few lines have comma-separated values
    int commaCount = 0;
    for (int i = 0; i < lines.length && i < 3; i++) {
      if (lines[i].contains(',')) {
        commaCount++;
      }
    }
    
    return commaCount >= 2; // At least 2 lines should have commas
  }
  
  /// Check if file is plain text
  bool _isTextFile(Uint8List bytes) {
    if (bytes.length < 10) return false;
    
    // Check if file contains mostly printable ASCII characters
    int printableCount = 0;
    for (int i = 0; i < bytes.length && i < 1000; i++) {
      if (bytes[i] >= 32 && bytes[i] <= 126) {
        printableCount++;
      }
    }
    
    final ratio = printableCount / (bytes.length > 1000 ? 1000 : bytes.length);
    return ratio > 0.9; // More than 90% printable characters
  }
} 