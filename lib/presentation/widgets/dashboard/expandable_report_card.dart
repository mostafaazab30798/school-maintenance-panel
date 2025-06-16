import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' as intl;
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:convert';

class ExpandableReportCard extends StatefulWidget {
  final Map<String, dynamic> report;

  const ExpandableReportCard({super.key, required this.report});

  @override
  State<ExpandableReportCard> createState() => _ExpandableReportCardState();
}

class _ExpandableReportCardState extends State<ExpandableReportCard>
    with SingleTickerProviderStateMixin {
  bool expanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _downloadReportZip() async {
    final schoolName = widget.report['school_name'] ?? 'report';
    final beforePhotos =
        (widget.report['images'] as List?)?.cast<String>() ?? [];
    final afterPhotos =
        (widget.report['completion_photos'] as List?)?.cast<String>() ?? [];
    final description = widget.report['description'] ?? '';
    final completionNote = widget.report['completion_note'] ?? '';

    final archive = Archive();
    final dio = Dio();

    // Helper to sanitize file/folder names
    // Use the school name directly for the zip file (supports Arabic letters)
    final schoolZipName = schoolName;

    // Add before photos
    for (int i = 0; i < beforePhotos.length; i++) {
      final url = beforePhotos[i];
      try {
        final response = await dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final fileName = 'before/before_${i + 1}${_getFileExtension(url)}';
        archive.addFile(
            ArchiveFile(fileName, response.data!.length, response.data));
      } catch (e) {
        // Optionally handle download error
      }
    }
    // Add after photos
    for (int i = 0; i < afterPhotos.length; i++) {
      final url = afterPhotos[i];
      try {
        final response = await dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final fileName = 'after/after_${i + 1}${_getFileExtension(url)}';
        archive.addFile(
            ArchiveFile(fileName, response.data!.length, response.data));
      } catch (e) {
        // Optionally handle download error
      }
    }
    // Add description and completion note as a text file
    final textContent =
        'الوصف:\n$description\n\nملاحظة الإغلاق:\n$completionNote';
    archive.addFile(ArchiveFile('report_info.txt',
        utf8.encode(textContent).length, utf8.encode(textContent)));

    // Encode the zip
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) return;

    // Save the zip file
    await FileSaver.instance.saveFile(
      name: '${schoolZipName}_report.zip',
      bytes: Uint8List.fromList(zipData),
      ext: 'zip',
      mimeType: MimeType.zip,
    );
  }

  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty && segments.last.contains('.')) {
      return '.${segments.last.split('.').last}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final dateFormat = intl.DateFormat('yyyy-MM-dd hh:mm a');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: theme.copyWith(
            dividerColor: Colors.transparent,
            expansionTileTheme: ExpansionTileThemeData(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              iconColor: _priorityColor(report['priority']),
              collapsedIconColor: _priorityColor(report['priority']),
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            onExpansionChanged: (v) {
              setState(() => expanded = v);
              if (v) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _priorityColor(report['priority']).withOpacity(0.8),
                    _priorityColor(report['priority']),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _priorityColor(report['priority']).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _priorityIcon(report['priority']),
                color: Colors.white,
                size: 20,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download Report',
              onPressed: _downloadReportZip,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report['school_name'] ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.grey[800],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _priorityColor(report['priority']).withOpacity(0.1),
                            _priorityColor(report['priority']).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _priorityColor(report['priority']),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        report['priority'] == 'Routine' ? 'روتيني' : 'طارئ',
                        style: TextStyle(
                          color: _priorityColor(report['priority']),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report['description'] ?? '-',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: expanded ? null : 2,
                  overflow: expanded ? null : TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        dateFormat.format(DateTime.parse(report['created_at'])),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _priorityColor(report['priority']).withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    _buildDetailRow(
                      icon: Icons.supervisor_account_rounded,
                      title: 'المشرف:',
                      value: report['username'] ?? '-',
                      isDark: isDark,
                    ),
                    if (report['scheduled_date'] != null)
                      _buildDetailRow(
                        icon: Icons.schedule_rounded,
                        title: 'تاريخ الجدولة:',
                        value: dateFormat
                            .format(DateTime.parse(report['scheduled_date'])),
                        isDark: isDark,
                      ),
                    if (report['closed_at'] != null)
                      _buildDetailRow(
                        icon: Icons.check_circle_rounded,
                        title: 'تاريخ الإنهاء:',
                        value: dateFormat
                            .format(DateTime.parse(report['closed_at'])),
                        isDark: isDark,
                        isCompleted: true,
                      ),
                    if (report['completion_note'] != null)
                      _buildDetailRow(
                        icon: Icons.check_circle_rounded,
                        title: 'ملاحظة الاغلاق',
                        value: report['completion_note'] ?? '-',
                        isDark: isDark,
                        isCompleted: true,
                      ),
                    if ((report['images'] as List?)?.isNotEmpty ?? false)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]?.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  size: 20,
                                  color: _priorityColor(report['priority']),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'الصور المرفقة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _priorityColor(report['priority'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(report['images'] as List).length}',
                                    style: TextStyle(
                                      color: _priorityColor(report['priority']),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(
                                  (report['images'] as List).length, (i) {
                                final url = report['images'][i];
                                return GestureDetector(
                                  onTap: () => _showImageDialog(url),
                                  child: Hero(
                                    tag: 'image_[0mi',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: url,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: 90,
                                                height: 90,
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.zoom_in_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    if ((report['completion_photos'] as List?)?.isNotEmpty ??
                        false)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]?.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'صور بعد الإنجاز',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(report['completion_photos'] as List).length}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(
                                  (report['completion_photos'] as List).length,
                                  (i) {
                                final url = report['completion_photos'][i];
                                return GestureDetector(
                                  onTap: () => _showImageDialog(url),
                                  child: Hero(
                                    tag: 'completion_photo_[0mi',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: url,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: 90,
                                                height: 90,
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.zoom_in_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    bool isCompleted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isDark ? Colors.grey[700]!.withOpacity(0.5) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : _priorityColor(widget.report['priority']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isCompleted
                  ? Colors.green
                  : _priorityColor(widget.report['priority']),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'Emergency':
        return const Color(0xFFE53E3E);
      case 'Routine':
        return const Color(0xFF3182CE);
      default:
        return const Color(0xFF718096);
    }
  }

  IconData _priorityIcon(String? priority) {
    switch (priority) {
      case 'Emergency':
        return Icons.priority_high_rounded;
      case 'Routine':
        return Icons.schedule_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: 'image_dialog',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
