import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/supervisor_attendance.dart';
import '../../../data/repositories/supervisor_attendance_repository.dart';
import '../../../logic/blocs/attendance/attendance_bloc.dart';
import '../../../logic/blocs/attendance/attendance_event.dart';
import '../../../logic/blocs/attendance/attendance_state.dart';
import '../common/esc_dismissible_dialog.dart';

class AttendanceDialog extends StatelessWidget {
  final String supervisorId;
  final String supervisorName;

  const AttendanceDialog({
    super.key,
    required this.supervisorId,
    required this.supervisorName,
  });

  static void show(BuildContext context, String supervisorId, String supervisorName) {
    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => BlocProvider(
        create: (context) => AttendanceBloc(
          SupervisorAttendanceRepository(Supabase.instance.client),
        )..add(LoadAttendanceForSupervisor(supervisorId: supervisorId)),
        child: AttendanceDialog(
          supervisorId: supervisorId,
          supervisorName: supervisorName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: _buildContent(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سجل الحضور',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  supervisorName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        return switch (state) {
          AttendanceLoading() => _buildLoading(context, isDark),
          AttendanceError() => _buildError(context, isDark, state.message),
          AttendanceLoaded() => _buildAttendanceList(context, isDark, state.attendance),
          _ => const SizedBox(),
        };
      },
    );
  }

  Widget _buildLoading(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
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
          const SizedBox(height: 24),
          Text(
            'جاري تحميل سجل الحضور...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
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
          const SizedBox(height: 24),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<AttendanceBloc>().add(
                  LoadAttendanceForSupervisor(supervisorId: supervisorId),
                ),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(BuildContext context, bool isDark, List<SupervisorAttendance> attendance) {
    if (attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
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
                  Icons.calendar_today_outlined,
                  color: Color(0xFF3B82F6),
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا يوجد سجل حضور',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لم يتم العثور على أي سجل حضور لهذا المشرف.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendance.length,
      itemBuilder: (context, index) {
        final record = attendance[index];
        return _buildAttendanceCard(context, isDark, record);
      },
    );
  }

  Widget _buildAttendanceCard(BuildContext context, bool isDark, SupervisorAttendance record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Photo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: record.photoUrl.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: InteractiveViewer(
                                child: Image.network(record.photoUrl),
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          record.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Color(0xFF64748B),
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF64748B),
                            size: 32,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Date and time info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ الحضور',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(record.createdAt),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(record.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            // // Action buttons
            // Column(
            //   children: [
            //     IconButton(
            //       onPressed: () {
            //         // TODO: Implement edit functionality
            //       },
            //       icon: Icon(
            //         Icons.edit,
            //         color: isDark ? Colors.white70 : Colors.black54,
            //         size: 20,
            //       ),
            //     ),
            //     IconButton(
            //       onPressed: () {
            //         _showDeleteConfirmation(context, isDark, record);
            //       },
            //       icon: Icon(
            //         Icons.delete,
            //         color: const Color(0xFFEF4444),
            //         size: 20,
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(BuildContext context, bool isDark, SupervisorAttendance record) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'تأكيد الحذف',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف سجل الحضور هذا؟',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AttendanceBloc>().add(
                    DeleteAttendance(
                      id: record.id,
                      supervisorId: supervisorId,
                    ),
                  );
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
} 