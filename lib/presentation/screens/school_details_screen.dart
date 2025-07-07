import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/services/school_assignment_service.dart';
import '../../data/models/school.dart';
import '../../data/models/supervisor.dart';
import '../../data/models/report.dart';
import '../../data/models/maintenance_report.dart';
import '../../data/models/achievement_photo.dart';
import '../../data/models/damage_count.dart';
import '../../data/models/maintenance_count.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../widgets/common/common_widgets.dart';

class SchoolDetailsScreen extends StatefulWidget {
  final String schoolId;

  const SchoolDetailsScreen({super.key, required this.schoolId});

  @override
  State<SchoolDetailsScreen> createState() => _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends State<SchoolDetailsScreen> {
  late final SchoolAssignmentService _schoolService;
  late final SupervisorRepository _supervisorRepository;
  late final ReportRepository _reportRepository;
  late final MaintenanceReportRepository _maintenanceRepository;
  late final DamageCountRepository _damageCountRepository;
  late final MaintenanceCountRepository _maintenanceCountRepository;

  School? _school;
  List<Supervisor> _supervisors = [];
  List<Report> _reports = [];
  List<MaintenanceReport> _maintenanceReports = [];
  List<AchievementPhoto> _achievementPhotos = [];
  List<DamageCount> _damageCounts = [];
  List<MaintenanceCount> _maintenanceCounts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _schoolService = SchoolAssignmentService(supabase);
    _supervisorRepository = SupervisorRepository(supabase);
    _reportRepository = ReportRepository(supabase);
    _maintenanceRepository = MaintenanceReportRepository(supabase);
    _damageCountRepository = DamageCountRepository(supabase);
    _maintenanceCountRepository = MaintenanceCountRepository(supabase);
    _loadSchoolDetails();
  }

  Future<void> _loadSchoolDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // First get school details to get the school name for other queries
      _school = await _getSchoolById(widget.schoolId);

      if (_school == null) {
        throw Exception('لا يمكن العثور على المدرسة');
      }

      // Now execute all other API calls in parallel using school info
      final results = await Future.wait([
        // 1. Get supervisor IDs for this school
        _getSupervisorIds(widget.schoolId),
        // 2. Get reports for this school using school name
        _getReportsForSchool(_school!.name),
        // 3. Get maintenance reports for this school using school name
        _getMaintenanceReportsForSchool(_school!.name),
        // 4. Get achievement photos for this school
        _getAchievementPhotosForSchool(widget.schoolId),
        // 5. Get damage counts for this school
        _getDamageCountsForSchool(widget.schoolId),
        // 6. Get maintenance counts for this school
        _getMaintenanceCountsForSchool(widget.schoolId),
      ]);

      // Extract results
      final supervisorIds = results[0] as List<String>;
      _reports = results[1] as List<Report>;
      _maintenanceReports = results[2] as List<MaintenanceReport>;
      _achievementPhotos = results[3] as List<AchievementPhoto>;
      _damageCounts = results[4] as List<DamageCount>;
      _maintenanceCounts = results[5] as List<MaintenanceCount>;

      // Get supervisor details if we have IDs (separate call since it depends on previous result)
      if (supervisorIds.isNotEmpty) {
        _supervisors = await _getSupervisorDetails(supervisorIds);
      } else {
        _supervisors = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Optimized helper methods for parallel data fetching
  Future<School?> _getSchoolById(String schoolId) async {
    try {
      final response = await Supabase.instance.client
          .from('schools')
          .select('*')
          .eq('id', schoolId)
          .maybeSingle();

      if (response != null) {
        return School.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching school: $e');
      return null;
    }
  }

  Future<List<String>> _getSupervisorIds(String schoolId) async {
    try {
      final response = await Supabase.instance.client
          .from('supervisor_schools')
          .select('supervisor_id')
          .eq('school_id', schoolId);

      return (response as List)
          .map((data) => data['supervisor_id'] as String)
          .toList();
    } catch (e) {
      print('Error fetching supervisor IDs: $e');
      return [];
    }
  }

  Future<List<Supervisor>> _getSupervisorDetails(
      List<String> supervisorIds) async {
    try {
      final response = await Supabase.instance.client
          .from('supervisors')
          .select('*')
          .inFilter('id', supervisorIds);

      return (response as List)
          .map((data) => Supervisor.fromMap(data))
          .toList();
    } catch (e) {
      print('Error fetching supervisor details: $e');
      return [];
    }
  }

  Future<List<Report>> _getReportsForSchool(String schoolName) async {
    try {
      final response = await Supabase.instance.client
          .from('reports')
          .select('*, supervisors(username)')
          .eq('school_name', schoolName)
          .order('created_at', ascending: false)
          .limit(5); // Reduced limit for faster loading

      return (response as List).map((data) => Report.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  Future<List<MaintenanceReport>> _getMaintenanceReportsForSchool(
      String schoolName) async {
    try {
      final response = await Supabase.instance.client
          .from('maintenance_reports')
          .select('*, supervisors(username)')
          .eq('school_name', schoolName)
          .order('created_at', ascending: false)
          .limit(5); // Reduced limit for faster loading

      return (response as List)
          .map((data) => MaintenanceReport.fromMap(data))
          .toList();
    } catch (e) {
      print('Error fetching maintenance reports: $e');
      return [];
    }
  }

  Future<List<AchievementPhoto>> _getAchievementPhotosForSchool(
      String schoolId) async {
    try {
      final response = await Supabase.instance.client
          .from('achievement_photos')
          .select('*')
          .eq('school_id', schoolId)
          .order('upload_timestamp', ascending: false)
          .limit(10); // Reduced limit for faster loading

      return (response as List)
          .map((data) => AchievementPhoto.fromMap(data))
          .toList();
    } catch (e) {
      print('Error fetching achievement photos: $e');
      return [];
    }
  }

  Future<List<DamageCount>> _getDamageCountsForSchool(String schoolId) async {
    try {
      return await _damageCountRepository.getDamageCounts(
        schoolId: schoolId,
        limit: 50, // Reduced limit for faster loading
      );
    } catch (e) {
      print('Error fetching damage counts: $e');
      return [];
    }
  }

  Future<List<MaintenanceCount>> _getMaintenanceCountsForSchool(
      String schoolId) async {
    try {
      return await _maintenanceCountRepository.getMaintenanceCounts(
        schoolId: schoolId,
        limit: 50, // Reduced limit for faster loading
      );
    } catch (e) {
      print('Error fetching maintenance counts: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _school?.name ?? 'تفاصيل المدرسة',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'جارٍ تحميل بيانات المدرسة...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.red.withOpacity(0.7)
                  : Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSchoolDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_school == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا يمكن العثور على المدرسة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // // School Info Section
          // _buildSchoolInfoSection(),
          // const SizedBox(height: 24),

          // Supervisors Section
          _buildSupervisorsSection(),
          const SizedBox(height: 24),

          // Statistics Section
          _buildStatisticsSection(),
          const SizedBox(height: 24),

          // Achievements Section
          _buildAchievementsSection(),
          const SizedBox(height: 24),

          // Reports Section
          _buildReportsSection(),
          const SizedBox(height: 24),

          // Maintenance Reports Section
          _buildMaintenanceReportsSection(),
        ],
      ),
    );
  }

  // Widget _buildSchoolInfoSection() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).brightness == Brightness.dark
  //           ? const Color(0xFF1E293B)
  //           : Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Theme.of(context).brightness == Brightness.dark
  //               ? Colors.black.withOpacity(0.3)
  //               : Colors.grey.withOpacity(0.1),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               width: 48,
  //               height: 48,
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFF10B981).withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: const Icon(
  //                 Icons.school,
  //                 color: Color(0xFF10B981),
  //                 size: 24,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Text(
  //                 'معلومات المدرسة',
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.w700,
  //                   color: Theme.of(context).brightness == Brightness.dark
  //                       ? Colors.white
  //                       : const Color(0xFF1E293B),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 20),
  //         _buildInfoRow(Icons.school, 'اسم المدرسة', _school!.name),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.6)
              : Colors.grey.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.8)
                : const Color(0xFF475569),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.supervisor_account,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'المشرفون المسؤولون (${_supervisors.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_supervisors.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'لا يوجد مشرفون مسؤولون عن هذه المدرسة',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_supervisors.take(3).map((supervisor) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F172A).withOpacity(0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            const Color(0xFF8B5CF6).withOpacity(0.1),
                        child: Text(
                          supervisor.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          supervisor.username,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'إحصائيات المدرسة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'البلاغات',
                  _reports.length.toString(),
                  Icons.report,
                  const Color(0xFF3B82F6),
                  onTap: _reports.isNotEmpty
                      ? () {
                          print(
                              'Navigating to reports for school: ${_school!.name}');
                          context.push(
                              '/reports?schoolName=${Uri.encodeComponent(_school!.name)}&title=بلاغات ${_school!.name}');
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'الصيانة',
                  _maintenanceReports.length.toString(),
                  Icons.build,
                  const Color(0xFFEF4444),
                  onTap: _maintenanceReports.isNotEmpty
                      ? () {
                          print(
                              'Navigating to maintenance reports for school: ${_school!.name}');
                          context.push(
                              '/maintenance-reports?schoolName=${Uri.encodeComponent(_school!.name)}&title=صيانة ${_school!.name}');
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'حصر الأضرار',
                  _damageCounts.length.toString(),
                  Icons.warning,
                  const Color(0xFFFF6B6B),
                  onTap: _damageCounts.isNotEmpty
                      ? () {
                          print(
                              'Navigating to damage inventory for school: ${_school!.name} (ID: ${widget.schoolId})');
                          context.push(
                              '/damage-inventory?schoolId=${widget.schoolId}&schoolName=${Uri.encodeComponent(_school!.name)}');
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'حصر الصيانة',
                  _maintenanceCounts.length.toString(),
                  Icons.inventory,
                  const Color(0xFF4ECDC4),
                  onTap: _maintenanceCounts.isNotEmpty
                      ? () {
                          print(
                              'Navigating to maintenance counts for school: ${_school!.name} (ID: ${widget.schoolId})');
                          context.push(
                              '/count-inventory?schoolId=${widget.schoolId}&schoolName=${Uri.encodeComponent(_school!.name)}');
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: onTap != null
              ? Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 2,
                ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.7),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: color,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'اضغط للعرض',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (int.parse(value) == 0) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'لا توجد بيانات',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(
      BuildContext context, AchievementPhoto achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              // Background overlay
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.9),
                ),
              ),
              // Image container
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      // Image
                      Flexible(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            achievement.photoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.withOpacity(0.3),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 64,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'فشل في تحميل الصورة',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Description
                      if (achievement.photoDescription != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement.achievementTypeDisplayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement.photoDescription!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تاريخ الرفع: ${achievement.uploadTimestamp.day}/${achievement.uploadTimestamp.month}/${achievement.uploadTimestamp.year}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection() {
    // Group achievements by type
    final maintenanceAchievements = _achievementPhotos
        .where((photo) => photo.achievementType == 'maintenance_achievement')
        .toList();
    final acAchievements = _achievementPhotos
        .where((photo) => photo.achievementType == 'ac_achievement')
        .toList();
    final checklistAchievements = _achievementPhotos
        .where((photo) => photo.achievementType == 'checklist')
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'الإنجازات (${_achievementPhotos.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_achievementPhotos.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'لا توجد إنجازات لهذه المدرسة',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Maintenance Achievements
                if (maintenanceAchievements.isNotEmpty)
                  _buildAchievementCategory(
                    'مشهد انجاز صيانة',
                    maintenanceAchievements,
                    const Color(0xFF3B82F6),
                    Icons.build,
                  ),

                // AC Achievements
                if (acAchievements.isNotEmpty) ...[
                  if (maintenanceAchievements.isNotEmpty)
                    const SizedBox(height: 24),
                  _buildAchievementCategory(
                    'مشهد انجاز تكييف',
                    acAchievements,
                    const Color(0xFF06B6D4),
                    Icons.ac_unit,
                  ),
                ],

                // Checklist Achievements
                if (checklistAchievements.isNotEmpty) ...[
                  if (maintenanceAchievements.isNotEmpty ||
                      acAchievements.isNotEmpty)
                    const SizedBox(height: 24),
                  _buildAchievementCategory(
                    'تشيك ليست',
                    checklistAchievements,
                    const Color(0xFF10B981),
                    Icons.checklist,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementCategory(
    String title,
    List<AchievementPhoto> achievements,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$title (${achievements.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: achievements.take(3).map((achievement) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0F172A).withOpacity(0.5)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, achievement),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.network(
                          achievement.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.withOpacity(0.3),
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (achievement.photoDescription != null) ...[
                          Text(
                            achievement.photoDescription!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          '${achievement.uploadTimestamp.day}/${achievement.uploadTimestamp.month}/${achievement.uploadTimestamp.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReportsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.report_outlined,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'البلاغات (${_reports.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (_reports.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to reports filtered by school name
                    context.push(
                        '/reports?schoolName=${Uri.encodeComponent(_school!.name)}&title=بلاغات ${_school!.name}');
                  },
                  child: Text('عرض الكل'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_reports.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'لا توجد بلاغات لهذه المدرسة',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _reports.take(5).map((report) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F172A).withOpacity(0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              report.description,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildProgressIndicator(report.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report.supervisorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey.withOpacity(0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceReportsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'بلاغات الصيانة (${_maintenanceReports.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (_maintenanceReports.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to maintenance reports filtered by school name
                    context.push(
                        '/maintenance-reports?schoolName=${Uri.encodeComponent(_school!.name)}&title=بلاغات صيانة ${_school!.name}');
                  },
                  child: Text('عرض الكل'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_maintenanceReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'لا توجد بلاغات صيانة لهذه المدرسة',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _maintenanceReports.take(5).map((maintenance) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F172A).withOpacity(0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              maintenance.description,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildProgressIndicator(maintenance.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            maintenance.supervisorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey.withOpacity(0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${maintenance.createdAt.day}/${maintenance.createdAt.month}/${maintenance.createdAt.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'late':
        return const Color(0xFFEF4444);
      case 'late_completed':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'جارٍ';
      case 'late':
        return 'متأخر';
      case 'late_completed':
        return 'مكتمل متأخر';
      default:
        return status;
    }
  }

  double _getProgressValue(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 1.0;
      case 'late_completed':
        return 1.0;
      case 'pending':
        return 0.5;
      case 'late':
        return 0.3;
      default:
        return 0.0;
    }
  }

  Widget _buildProgressIndicator(String status) {
    final progress = _getProgressValue(status);
    final color = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          statusText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          height: 4,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
