import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/school_assignment_service.dart';
import '../../data/models/school.dart';
import '../../data/models/supervisor.dart';
import '../../data/models/achievement_photo.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../widgets/common/common_widgets.dart';

class SchoolsWithAchievementsScreen extends StatefulWidget {
  const SchoolsWithAchievementsScreen({super.key});

  @override
  State<SchoolsWithAchievementsScreen> createState() =>
      _SchoolsWithAchievementsScreenState();
}

class _SchoolsWithAchievementsScreenState
    extends State<SchoolsWithAchievementsScreen> {
  late final AdminService _adminService;
  late final SchoolAssignmentService _schoolService;
  late final SupervisorRepository _supervisorRepository;

  List<Map<String, dynamic>> _schoolsWithAchievements = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _adminService = AdminService(supabase);
    _schoolService = SchoolAssignmentService(supabase);
    _supervisorRepository = SupervisorRepository(supabase);
    _loadSchoolsWithAchievements();
  }

  Future<void> _loadSchoolsWithAchievements() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current admin info
      final currentAdmin = await _adminService.getCurrentAdmin();
      if (currentAdmin == null) {
        throw Exception('لا يمكن العثور على بيانات المدير');
      }

      // Get all achievement photos and group by school
      final achievementsResponse = await Supabase.instance.client
          .from('achievement_photos')
          .select('*')
          .order('upload_timestamp', ascending: false);

      // Group achievements by school
      final Map<String, List<AchievementPhoto>> schoolAchievements = {};
      for (final achievementData in achievementsResponse) {
        final achievement = AchievementPhoto.fromMap(achievementData);
        if (achievement.schoolId != null && achievement.schoolName != null) {
          if (!schoolAchievements.containsKey(achievement.schoolId)) {
            schoolAchievements[achievement.schoolId!] = [];
          }
          schoolAchievements[achievement.schoolId]!.add(achievement);
        }
      }

      // Get supervisors under this admin to filter schools
      final supervisors = await _supervisorRepository.fetchSupervisors(
          adminId: currentAdmin.id);

      // Get all schools for these supervisors
      List<School> allSchools = [];
      for (final supervisor in supervisors) {
        final supervisorSchools =
            await _schoolService.getSchoolsForSupervisor(supervisor.id);
        allSchools.addAll(supervisorSchools);
      }

      // Remove duplicates and filter only schools with achievements
      final uniqueSchools = <String, School>{};
      for (final school in allSchools) {
        if (schoolAchievements.containsKey(school.id)) {
          uniqueSchools[school.id] = school;
        }
      }

      // Create the final list with achievement counts
      final schoolsWithAchievementsList = <Map<String, dynamic>>[];
      for (final school in uniqueSchools.values) {
        final achievements = schoolAchievements[school.id] ?? [];
        schoolsWithAchievementsList.add({
          'school': school,
          'achievements': achievements,
          'achievement_count': achievements.length,
          'latest_achievement':
              achievements.isNotEmpty ? achievements.first : null,
        });
      }

      // Sort by achievement count (descending)
      schoolsWithAchievementsList.sort((a, b) => (b['achievement_count'] as int)
          .compareTo(a['achievement_count'] as int));

      setState(() {
        _schoolsWithAchievements = schoolsWithAchievementsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSchools {
    if (_searchQuery.isEmpty) return _schoolsWithAchievements;

    return _schoolsWithAchievements.where((schoolData) {
      final school = schoolData['school'] as School;
      final name = school.name.toLowerCase();
      final address = school.address?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || address.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'المشاهد والفحوصات',
            style: AppFonts.appBarTitle(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadSchoolsWithAchievements,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E293B),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFF1F5F9),
                    ],
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'البحث في المدارس...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
            SizedBox(height: 16),
            Text(
              'جارٍ تحميل المدارس...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
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
              onPressed: _loadSchoolsWithAchievements,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return _buildSchoolsList(_filteredSchools);
  }

  Widget _buildSchoolsList(List<Map<String, dynamic>> filteredSchools) {
    if (filteredSchools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'لا توجد مدارس لديها إنجازات'
                  : 'لا توجد مدارس تطابق البحث',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.7),
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'جرب البحث بكلمات مختلفة',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredSchools.length,
      itemBuilder: (context, index) {
        final schoolData = filteredSchools[index];
        return _buildSchoolCard(schoolData);
      },
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> schoolData) {
    final school = schoolData['school'] as School;
    final achievements = schoolData['achievements'] as List<AchievementPhoto>;
    final achievementCount = schoolData['achievement_count'] as int;
    final latestAchievement =
        schoolData['latest_achievement'] as AchievementPhoto?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/school-details/${school.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // School Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // School Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    if (school.address != null &&
                        school.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        school.address!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Achievement count
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Color(0xFF10B981),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$achievementCount إنجاز',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Latest achievement type
                        if (latestAchievement != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              latestAchievement.achievementTypeDisplayName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
