import '../../data/models/excel_report_data.dart';

class ExcelDataService {
  static final ExcelDataService _instance = ExcelDataService._internal();
  factory ExcelDataService() => _instance;
  ExcelDataService._internal();

  Map<String, List<ExcelReportData>> _excelReportsBySchool = {};

  void setExcelData(Map<String, List<ExcelReportData>> excelReportsBySchool) {
    _excelReportsBySchool = Map.from(excelReportsBySchool);
    print('📊 ExcelDataService: Stored data for ${_excelReportsBySchool.length} schools');
    print('📊 Schools: ${_excelReportsBySchool.keys.toList()}');
  }

  Map<String, List<ExcelReportData>> getExcelData() {
    return Map.from(_excelReportsBySchool);
  }

  void clearExcelData() {
    _excelReportsBySchool.clear();
    print('📊 ExcelDataService: Cleared Excel data');
  }

  bool hasExcelData() {
    return _excelReportsBySchool.isNotEmpty;
  }

  List<String> getAvailableSchools() {
    return _excelReportsBySchool.keys.toList()..sort();
  }
} 