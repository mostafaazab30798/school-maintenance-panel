import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/supervisor.dart';
import '../../saudi_plate.dart';
import '../../common/esc_dismissible_dialog.dart';

class SupervisorDetailDialog extends StatelessWidget {
  final Map<String, dynamic> supervisor;

  const SupervisorDetailDialog({
    super.key,
    required this.supervisor,
  });

  @override
  Widget build(BuildContext context) {
    final supervisorId = supervisor['id'] as String? ?? '';
    final username = supervisor['username'] as String? ?? 'غير محدد';

    return FutureBuilder<Supervisor?>(
      future: _fetchSupervisorDetails(supervisorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 400,
              height: 300,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل تفاصيل المشرف...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 400,
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('حدث خطأ في تحميل تفاصيل المشرف'),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final supervisorData = snapshot.data!;
        final stats = supervisor['stats'] as Map<String, dynamic>;

        return Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 500,
            height: 650,
            child: Column(
              children: [
                // Enhanced Header
                _buildEnhancedSupervisorHeader(supervisorData, supervisor),

                // Content (scrollable to prevent flex overflow)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information Section
                        _buildPersonalInfoSection(context, supervisorData),
                        const SizedBox(height: 16),

                        // Saudi License Plate Section
                        _buildSaudiLicensePlateSection(context, supervisorData),
                        const SizedBox(height: 16),

                        // Status & Assignment Section
                        _buildStatusSection(context, supervisorData, stats),
                      ],
                    ),
                  ),
                ),

                // Close Button Only
                _buildSimpleActionButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Supervisor?> _fetchSupervisorDetails(String supervisorId) async {
    try {
      final response = await Supabase.instance.client
          .from('supervisors')
          .select('*')
          .eq('id', supervisorId)
          .single();

      return Supervisor.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching supervisor details: $e');
      return null;
    }
  }

  Widget _buildEnhancedSupervisorHeader(
      Supervisor supervisor, Map<String, dynamic> supervisorStats) {
    final username = supervisor.username;
    final email = supervisor.email;
    final workId = supervisor.workId;
    final isAssigned = supervisor.adminId != null;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF1E40AF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'س',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.isNotEmpty ? email : 'البريد الإلكتروني غير محدد',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (workId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'رقم وظيفي: $workId',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAssigned
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : const Color(0xFFF59E0B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAssigned
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAssigned ? Icons.check_circle : Icons.schedule,
                        color: isAssigned
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isAssigned ? 'مُعيّن' : 'غير مُعيّن',
                        style: TextStyle(
                          color: isAssigned
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
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
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, Supervisor supervisor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF8B5CF6),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'المعلومات الشخصية',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF334155)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF475569)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildEnhancedDetailItem(
                  context,
                  'رقم الهاتف',
                  supervisor.phone.isEmpty ? 'غير محدد' : supervisor.phone,
                  Icons.phone_outlined,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedDetailItem(
                  context,
                  'رقم الهوية/الإقامة',
                  supervisor.iqamaId.isEmpty ? 'غير محدد' : supervisor.iqamaId,
                  Icons.credit_card_outlined,
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaudiLicensePlateSection(BuildContext context, Supervisor supervisor) {
    final hasPlateData = supervisor.plateNumbers.isNotEmpty ||
        supervisor.plateEnglishLetters.isNotEmpty ||
        supervisor.plateArabicLetters.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'لوحة السيارة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF334155)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF475569)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: hasPlateData
              ? Center(
                  child: Container(
                    height: 90,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Transform.scale(
                        scale: 0.8,
                        child: SaudiLicensePlate(
                          englishNumbers: supervisor.plateNumbers.isEmpty
                              ? '0000'
                              : supervisor.plateNumbers,
                          arabicLetters: supervisor.plateArabicLetters.isEmpty
                              ? 'غ غ غ'
                              : supervisor.plateArabicLetters,
                          englishLetters: supervisor.plateEnglishLetters.isEmpty
                              ? 'AAA'
                              : supervisor.plateEnglishLetters,
                          isHorizontal: true,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.no_accounts_outlined,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد معلومات لوحة السيارة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(
      BuildContext context, Supervisor supervisor, Map<String, dynamic> supervisorStats) {
    final isAssigned = supervisor.adminId != null;
    final adminName = supervisorStats['admin_name'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'حالة التعيين',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAssigned
                  ? [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF10B981).withOpacity(0.05),
                    ]
                  : [
                      const Color(0xFFF59E0B).withOpacity(0.1),
                      const Color(0xFFF59E0B).withOpacity(0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAssigned
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFF59E0B).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAssigned
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFFF59E0B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isAssigned
                          ? Icons.check_circle_outline
                          : Icons.schedule_outlined,
                      color: isAssigned
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAssigned ? 'مُعيّن لمسؤول' : 'غير مُعيّن',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isAssigned
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        if (isAssigned) ...[
                          const SizedBox(height: 2),
                          FutureBuilder<String?>(
                            future: _getAdminName(supervisor.adminId!),
                            builder: (context, snapshot) {
                              final displayName =
                                  snapshot.data ?? adminName ?? 'غير معروف';
                              return Text(
                                '$displayName : المسؤول',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String?> _getAdminName(String adminId) async {
    try {
      final response = await Supabase.instance.client
          .from('admins')
          .select('name')
          .eq('id', adminId)
          .single();

      return response['name'] as String?;
    } catch (e) {
      debugPrint('Error fetching admin name: $e');
      return null;
    }
  }

  Widget _buildSimpleActionButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF334155)
            : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF475569)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_outlined, size: 16),
          label: const Text('إغلاق', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDetailItem(BuildContext context, String label,
      String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, Map<String, dynamic> supervisor) {
    context.showEscDismissibleDialog(
      barrierDismissible: false,
      builder: (dialogContext) => SupervisorDetailDialog(
        supervisor: supervisor,
      ),
    );
  }
}