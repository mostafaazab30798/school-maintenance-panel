import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

// For web download
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../../../data/models/supervisor_attendance.dart';

Future<void> exportSupervisorsAttendanceToExcel(
  List<Map<String, dynamic>> supervisorsWithStats,
  Future<List<SupervisorAttendance>> Function(String supervisorId) fetchAttendance,
) async {
  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'Attendance Report';

  // Create date formatter
  final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  final timeFormatter = DateFormat('HH:mm');

  // Enhanced Header with styling
  final headerRange = sheet.getRangeByName('A1:F1');
  headerRange.cellStyle.backColor = '#4472C4';
  headerRange.cellStyle.fontColor = '#FFFFFF';
  headerRange.cellStyle.bold = true;
  headerRange.cellStyle.fontSize = 12;

  // Header columns
  sheet.getRangeByName('A1').setText('Supervisor Name');
  sheet.getRangeByName('B1').setText('Supervisor Email');
  sheet.getRangeByName('C1').setText('Attendance Date');
  sheet.getRangeByName('D1').setText('Arrival Time');
  sheet.getRangeByName('E1').setText('Leave Time');
  sheet.getRangeByName('F1').setText('Total Hours');

  // Set column widths for better readability
  sheet.setColumnWidthInPixels(1, 150); // Supervisor Name
  sheet.setColumnWidthInPixels(2, 200); // Supervisor Email
  sheet.setColumnWidthInPixels(3, 120); // Attendance Date
  sheet.setColumnWidthInPixels(4, 100); // Arrival Time
  sheet.setColumnWidthInPixels(5, 100); // Leave Time
  sheet.setColumnWidthInPixels(6, 120); // Total Hours

  int row = 2;
  for (final supervisor in supervisorsWithStats) {
    final name = supervisor['username'] ?? '';
    final email = supervisor['email'] ?? '';
    final supervisorId = supervisor['id'] ?? '';
    final attendanceList = await fetchAttendance(supervisorId);

    for (final attendance in attendanceList) {
      // Format the attendance date
      final attendanceDate = DateFormat('yyyy-MM-dd').format(attendance.createdAt);
      final arrivalTime = timeFormatter.format(attendance.createdAt);
      
      // Calculate total hours if both arrival and leave times exist
      String totalHours = '';
      if (attendance.leaveTime != null) {
        final duration = attendance.leaveTime!.difference(attendance.createdAt);
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        totalHours = '${hours}h ${minutes}m';
      }

      // Add data to Excel
      sheet.getRangeByName('A$row').setText(name);
      sheet.getRangeByName('B$row').setText(email);
      sheet.getRangeByName('C$row').setText(attendanceDate);
      sheet.getRangeByName('D$row').setText(arrivalTime);
      sheet.getRangeByName('E$row').setText(
        attendance.leaveTime != null 
          ? timeFormatter.format(attendance.leaveTime!)
          : 'Not Recorded'
      );
      sheet.getRangeByName('F$row').setText(totalHours);

      // Apply alternating row colors for better readability
      if (row % 2 == 0) {
        final range = sheet.getRangeByName('A$row:F$row');
        range.cellStyle.backColor = '#F2F2F2';
      }

      row++;
    }
  }

  // Auto-fit rows for better appearance
  sheet.autoFitRow(1);

  // Add summary information
  final summaryRow = row + 1;
  sheet.getRangeByName('A$summaryRow').setText('Report Generated:');
  sheet.getRangeByName('B$summaryRow').setText(dateFormatter.format(DateTime.now()));
  sheet.getRangeByName('A$summaryRow').cellStyle.bold = true;

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  // Generate filename with timestamp
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final filename = 'attendance_report_$timestamp.xlsx';

  if (kIsWeb) {
    // For web: use AnchorElement to trigger download
    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    // For mobile/desktop: save to file and open
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$filename';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(path);
  }
} 