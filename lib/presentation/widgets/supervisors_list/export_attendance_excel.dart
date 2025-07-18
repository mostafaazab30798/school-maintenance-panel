import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

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

  // Header
  sheet.getRangeByName('A1').setText('Supervisor Name');
  sheet.getRangeByName('B1').setText('Supervisor Email');
  sheet.getRangeByName('C1').setText('Attendance Date/Time');
  sheet.getRangeByName('D1').setText('Photo URL');

  int row = 2;
  for (final supervisor in supervisorsWithStats) {
    final name = supervisor['username'] ?? '';
    final email = supervisor['email'] ?? '';
    final supervisorId = supervisor['id'] ?? '';
    final attendanceList = await fetchAttendance(supervisorId);

    for (final attendance in attendanceList) {
      sheet.getRangeByName('A$row').setText(name);
      sheet.getRangeByName('B$row').setText(email);
      sheet.getRangeByName('C$row').setText(attendance.createdAt.toString());
      sheet.getRangeByName('D$row').setText(attendance.photoUrl);
      row++;
    }
  }

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  if (kIsWeb) {
    // For web: use AnchorElement to trigger download
    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'supervisors_attendance.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    // For mobile/desktop: save to file and open
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/supervisors_attendance.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(path);
  }
} 