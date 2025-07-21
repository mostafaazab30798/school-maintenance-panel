import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/supervisor.dart';
import '../../data/models/car_maintenance.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/car_maintenance_repository.dart';
import '../../logic/blocs/supervisors/supervisor_bloc.dart';
import '../../logic/blocs/supervisors/supervisor_event.dart';
import '../../logic/blocs/supervisors/supervisor_state.dart';
import '../../core/services/admin_service.dart';
import '../widgets/saudi_plate.dart';
import '../widgets/attendance/attendance_dialog.dart';
import '../widgets/super_admin/dialogs/car_maintenance_dialog.dart';
import '../widgets/common/esc_dismissible_dialog.dart';
import 'dart:ui';
import '../widgets/common/standard_refresh_button.dart';
import '../widgets/supervisors_list/export_attendance_excel.dart';
import '../../data/repositories/supervisor_attendance_repository.dart';
import '../../data/models/supervisor_attendance.dart';
import 'package:intl/intl.dart' as intl;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../widgets/common/shared_app_bar.dart';

class SupervisorListScreen extends StatelessWidget {
  const SupervisorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupervisorBloc(
        SupervisorRepository(Supabase.instance.client),
        AdminService(Supabase.instance.client),
      )..add(const SupervisorsStarted()),
      child: const _SupervisorListView(),
    );
  }
}

class _SupervisorListView extends StatelessWidget {
  const _SupervisorListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFBFC),
        appBar: SharedAppBar(
          title: 'قائمة المشرفين',
          actions: [
            _ExportAttendanceButton(),
            const SizedBox(width: 8),
            StandardRefreshButton(
              onPressed: () => context
                  .read<SupervisorBloc>()
                  .add(const SupervisorsStarted()),
            ),
          ],
        ),
        body: BlocBuilder<SupervisorBloc, SupervisorState>(
          builder: (context, state) => switch (state) {
            SupervisorLoading() => _buildLoading(context, isDark),
            SupervisorError() =>
              _buildError(context, isDark, state.message),
            SupervisorLoaded() =>
              _buildGrid(context, isDark, state.supervisors),
            _ => const SizedBox(),
          },
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'جاري تحميل المشرفين...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, String message) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            StandardRefreshElevatedButton(
              onPressed: () => context
                  .read<SupervisorBloc>()
                  .add(const SupervisorsStarted()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, bool isDark, List<Supervisor> supervisors) {
    if (supervisors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.people_outline_rounded,
                  color: Color(0xFF3B82F6),
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'لا يوجد مشرفين',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'لم يتم العثور على أي مشرفين في النظام حالياً.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20,
        top: 20,
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 1.2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: supervisors.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.all(4),
          child: _SupervisorCard(
            supervisor: supervisors[index],
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 2;
    if (width > 1000) return 2;
    if (width > 700) return 2;
    return 1;
  }
}

class _SupervisorCard extends StatefulWidget {
  final Supervisor supervisor;
  final bool isDark;

  const _SupervisorCard({required this.supervisor, required this.isDark});

  @override
  State<_SupervisorCard> createState() => _SupervisorCardState();
}

class _SupervisorCardState extends State<_SupervisorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  CarMaintenance? _carMaintenance;
  bool _isLoadingCarMaintenance = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.01,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Fetch car maintenance data
    _fetchCarMaintenanceData();
  }

  Future<void> _fetchCarMaintenanceData() async {
    if (_isLoadingCarMaintenance) return;
    
    setState(() {
      _isLoadingCarMaintenance = true;
    });

    try {
      final carMaintenanceRepository = CarMaintenanceRepository(Supabase.instance.client);
      final carMaintenance = await carMaintenanceRepository.getCarMaintenanceBySupervisorId(widget.supervisor.id);
      
      if (mounted) {
        setState(() {
          _carMaintenance = carMaintenance;
          _isLoadingCarMaintenance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCarMaintenance = false;
        });
      }
      debugPrint('Error fetching car maintenance data: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFF3B82F6).withOpacity(0.4)
                    : (widget.isDark ? Colors.white12 : Colors.black12),
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6)
                      .withOpacity(_isHovered ? 0.2 : 0.08),
                  blurRadius: _isHovered ? 30 : 20,
                  offset: const Offset(0, 12),
                  spreadRadius: _isHovered ? 3 : 0,
                ),
                if (!_isHovered)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Section - Avatar and Basic Info
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        _buildLicensePlate(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right Section - Car Maintenance and Attendance
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCarMaintenanceSection(),
                        const SizedBox(height: 16),
                        // Removed Attendance Section
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF3B82F6),
                    const Color(0xFF1D4ED8),
                    const Color(0xFF7C3AED),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.supervisor.username.isNotEmpty
                      ? widget.supervisor.username[0].toUpperCase()
                      : '؟',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.supervisor.username,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Small Attendance Button
                      _buildSmallAttendanceButton(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.15),
                          const Color(0xFF059669).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 16,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.supervisor.workId.isEmpty
                              ? 'غير محدد'
                              : 'الرقم الوظيفي : ${widget.supervisor.workId}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                widget.isDark ? Colors.white12 : Colors.black12,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallAttendanceButton() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8.0),
      child: SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: const Color(0xFF8B5CF6), width: 1),
            foregroundColor: const Color(0xFF8B5CF6),
            backgroundColor: widget.isDark ? const Color(0xFF2E1065).withOpacity(0.08) : const Color(0xFFF3F0FF),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text(
            'الحضور',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            AttendanceDialog.show(
              context,
              widget.supervisor.id,
              widget.supervisor.username,
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات الاتصال',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.email_outlined,
          'البريد الإلكتروني',
          widget.supervisor.email.isEmpty
              ? 'غير محدد'
              : widget.supervisor.email,
          const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                Icons.phone_outlined,
                'الهاتف',
                widget.supervisor.phone.isEmpty
                    ? 'غير محدد'
                    : widget.supervisor.phone,
                const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoRow(
                Icons.badge_outlined,
                'الهوية',
                widget.supervisor.iqamaId.isEmpty
                    ? 'غير محدد'
                    : widget.supervisor.iqamaId,
                const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLicensePlate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات السيارة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF10B981).withOpacity(0.08),
                const Color(0xFF059669).withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة السيارة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SaudiLicensePlate(
                          englishNumbers: widget.supervisor.plateNumbers,
                          arabicLetters: widget.supervisor.plateArabicLetters,
                          englishLetters: widget.supervisor.plateEnglishLetters,
                          isHorizontal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarMaintenanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.15),
                    const Color(0xFF059669).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.build_outlined,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'معلومات صيانة السيارة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            // Removed edit button
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      const Color(0xFF334155).withOpacity(0.8),
                      const Color(0xFF475569).withOpacity(0.6),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFF1F5F9),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoadingCarMaintenance
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                )
              : _carMaintenance == null
                  ? _buildNoCarMaintenanceData()
                  : _buildCarMaintenanceData(),
        ),
      ],
    );
  }

  Widget _buildNoCarMaintenanceData() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات صيانة للسيارة',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر التعديل لإضافة بيانات الصيانة',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCarMaintenanceData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Maintenance Meter Section
        if (_carMaintenance!.maintenanceMeter != null) ...[
          _buildMaintenanceMeterInfo(),
          const SizedBox(height: 20),
        ],

        // Tyre Changes Section
        if (_carMaintenance!.tyreChanges.isNotEmpty) ...[
          _buildTyreChangesSection(),
          const SizedBox(height: 20),
        ],

        // // Last Updated Info
        // _buildLastUpdatedInfo(),
      ],
    );
  }

  Widget _buildMaintenanceMeterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.08),
            const Color(0xFF059669).withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.speed_outlined,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عداد الصيانة',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_carMaintenance!.maintenanceMeter} كم',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (_carMaintenance!.maintenanceMeterDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'تاريخ القراءة: ${intl.DateFormat('yyyy/MM/dd').format(_carMaintenance!.maintenanceMeterDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyreChangesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tire_repair_outlined,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'تغييرات الإطارات',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._carMaintenance!.tyreChanges.map((change) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF59E0B).withOpacity(0.08),
                const Color(0xFFD97706).withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tire_repair_outlined,
                  color: Color(0xFFF59E0B),
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTyrePositionArabicLabel(change.tyrePosition),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تاريخ التغيير: ${intl.DateFormat('yyyy/MM/dd').format(change.changeDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  // Widget _buildLastUpdatedInfo() {
  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Colors.grey.withOpacity(0.05),
  //           Colors.grey.withOpacity(0.08),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: Colors.grey.withOpacity(0.15),
  //         width: 1.5,
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(6),
  //           decoration: BoxDecoration(
  //             color: Colors.grey.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(
  //             Icons.update_outlined,
  //             color: Colors.grey[600],
  //             size: 14,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'آخر تحديث',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.grey[600],
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               const SizedBox(height: 2),
  //               Text(
  //                 intl.DateFormat('yyyy/MM/dd HH:mm').format(_carMaintenance!.updatedAt),
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
  //                   fontWeight: FontWeight.w700,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _getTyrePositionArabicLabel(String position) {
    const Map<String, String> arabicLabels = {
      'front_left': 'أمامي يسار',
      'front_right': 'أمامي يمين',
      'rear_left': 'خلفي يسار',
      'rear_right': 'خلفي يمين',
      'spare': 'احتياطي',
    };
    return arabicLabels[position] ?? position;
  }

  void _openCarMaintenanceDialog() {
    context.showEscDismissibleDialog<bool>(
      barrierDismissible: false,
      builder: (dialogContext) => CarMaintenanceDialog(
        supervisorId: widget.supervisor.id,
        supervisorName: widget.supervisor.username,
        initialCarMaintenance: _carMaintenance,
      ),
    ).then((result) {
      if (result == true) {
        // Refresh the car maintenance data if it was updated
        _fetchCarMaintenanceData();
      }
    });
  }

  // Removed _buildAttendanceSection from the card body
}

class _ExportAttendanceButton extends StatefulWidget {
  @override
  State<_ExportAttendanceButton> createState() => _ExportAttendanceButtonState();
}

class _ExportAttendanceButtonState extends State<_ExportAttendanceButton> {
  bool _isExporting = false;

  Future<void> _export() async {
    if (_isExporting) return;
    
    setState(() => _isExporting = true);
    
    try {
      // Fetch all supervisors
      final supabase = Supabase.instance.client;
      final supervisorRepo = SupervisorRepository(supabase);
      final attendanceRepo = SupervisorAttendanceRepository(supabase);
      final supervisors = await supervisorRepo.fetchSupervisorsForCurrentAdmin();
      final dateFormat = intl.DateFormat('yyyy-MM-dd');
      final timeFormat = intl.DateFormat('HH:mm');

      final xlsio.Workbook workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      // Arabic headers
      sheet.getRangeByName('A1').setText('اسم المشرف');
      sheet.getRangeByName('B1').setText('البريد الإلكتروني');
      sheet.getRangeByName('C1').setText('تاريخ الحضور');
      sheet.getRangeByName('D1').setText('وقت الحضور');

      int row = 2;
      for (final supervisor in supervisors) {
        final attendanceList = await attendanceRepo.fetchAttendanceForSupervisor(supervisor.id);
        for (final attendance in attendanceList) {
          sheet.getRangeByName('A$row').setText(supervisor.username);
          sheet.getRangeByName('B$row').setText(supervisor.email);
          sheet.getRangeByName('C$row').setText(dateFormat.format(attendance.createdAt));
          sheet.getRangeByName('D$row').setText(timeFormat.format(attendance.createdAt));
          row++;
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      if (kIsWeb) {
        final blob = html.Blob([Uint8List.fromList(bytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'حضور المشرفين.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/حضور المشرفين.xlsx';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        await OpenFile.open(path);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('تم تصدير حضور المشرفين بنجاح!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('حدث خطأ أثناء التصدير: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF10B981).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isExporting ? null : _export,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                const SizedBox(width: 6),
                Text(
                  _isExporting ? 'جاري التصدير...' : 'تصدير الحضور',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
