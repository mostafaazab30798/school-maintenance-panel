import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' as intl;
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:convert';

class ExpandableMaintenanceCard extends StatefulWidget {
  final Map<String, dynamic> maintenanceReport;

  const ExpandableMaintenanceCard({super.key, required this.maintenanceReport});

  @override
  State<ExpandableMaintenanceCard> createState() =>
      _ExpandableMaintenanceCardState();
}

class _ExpandableMaintenanceCardState extends State<ExpandableMaintenanceCard>
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

  Future<void> _downloadMaintenanceZip() async {
    final schoolName = widget.maintenanceReport['school_name'] ?? 'maintenance';
    final beforePhotos =
        (widget.maintenanceReport['images'] as List?)?.cast<String>() ?? [];
    final afterPhotos = (widget.maintenanceReport['completion_photos'] as List?)
            ?.cast<String>() ??
        [];
    final description = widget.maintenanceReport['description'] ?? '';
    final completionNote = widget.maintenanceReport['completion_note'] ?? '';

    final archive = Archive();
    final dio = Dio();

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
    archive.addFile(ArchiveFile('maintenance_info.txt',
        utf8.encode(textContent).length, utf8.encode(textContent)));

    // Encode the zip
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) return;

    // Save the zip file
    await FileSaver.instance.saveFile(
      name: '${schoolZipName}_maintenance.zip',
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

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.maintenanceReport;
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
              iconColor: _statusColor(report['status']),
              collapsedIconColor: _statusColor(report['status']),
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
                    _statusColor(report['status']).withOpacity(0.8),
                    _statusColor(report['status']),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _statusColor(report['status']).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _statusIcon(report['status']),
                color: Colors.white,
                size: 20,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download Maintenance Report',
              onPressed: _downloadMaintenanceZip,
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
                            _statusColor(report['status']).withOpacity(0.1),
                            _statusColor(report['status']).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _statusColor(report['status']),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _translateStatus(report['status']),
                        style: TextStyle(
                          color: _statusColor(report['status']),
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
                            _statusColor(report['status']).withOpacity(0.2),
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
                                  color: _statusColor(report['status']),
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
                                    color: _statusColor(report['status'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(report['images'] as List).length}',
                                    style: TextStyle(
                                      color: _statusColor(report['status']),
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
                                    tag: 'maintenance_image_$i',
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                _statusColor(report['status'])
                                                    .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: url,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.image_rounded,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.broken_image_rounded,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
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
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'صور الإنجاز',
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
                                    tag: 'maintenance_completion_image_$i',
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: url,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.image_rounded,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.broken_image_rounded,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
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
                  : _statusColor(widget.maintenanceReport['status'])
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isCompleted
                  ? Colors.green
                  : _statusColor(widget.maintenanceReport['status']),
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

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFF3B82F6);
      case 'late':
        return const Color(0xFFF59E0B);
      case 'late_completed':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF059669);
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'late':
        return Icons.warning;
      case 'late_completed':
        return Icons.check_circle_outline;
      default:
        return Icons.build;
    }
  }

  String _translateStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'جاري العمل';
      case 'completed':
        return 'تم الانتهاء';
      case 'late':
        return 'متأخر';
      case 'late_completed':
        return 'منجز متأخر';
      default:
        return status ?? '';
    }
  }
}
