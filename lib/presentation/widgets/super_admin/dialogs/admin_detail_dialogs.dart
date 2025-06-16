import 'package:flutter/material.dart';
import '../../common/esc_dismissible_dialog.dart';

class AdminDetailDialogs {
  static void showAdminDetails(
    BuildContext context,
    dynamic admin,
    Map<String, dynamic> stats,
    List<Map<String, dynamic>> assignedSupervisors,
  ) {
    context.showEscDismissibleDialog(
      builder: (dialogContext) => AlertDialog(
        title: Text('تفاصيل المسؤول - ${admin.name ?? "غير محدد"}'),
        content: Container(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('الاسم:', admin.name ?? 'غير محدد'),
              _buildDetailRow('البريد الإلكتروني:', admin.email ?? 'غير محدد'),
              _buildDetailRow('الدور:', 'مسؤول مكتبي'),
              const Divider(height: 24),
              const Text(
                'الإحصائيات:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('عدد المشرفين:', '${stats['supervisors'] ?? 0}'),
              _buildDetailRow('إجمالي البلاغات:', '${stats['reports'] ?? 0}'),
              _buildDetailRow(
                  'إجمالي الصيانة:', '${stats['maintenance'] ?? 0}'),
              _buildDetailRow(
                  'البلاغات المكتملة:', '${stats['completed_reports'] ?? 0}'),
              _buildDetailRow('الصيانة المكتملة:',
                  '${stats['completed_maintenance'] ?? 0}'),
              _buildDetailRow(
                  'البلاغات المتأخرة:', '${stats['late_reports'] ?? 0}'),
              _buildDetailRow('المكتملة المتأخرة:',
                  '${stats['late_completed_reports'] ?? 0}'),
              _buildDetailRow('معدل الإنجاز:',
                  '${((stats['completion_rate'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
              const Divider(height: 24),
              const Text(
                'المشرفين المُعيّنين:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (assignedSupervisors.isEmpty)
                const Text('لا يوجد مشرفين مُعيّنين',
                    style: TextStyle(color: Color(0xFF64748B)))
              else
                ...assignedSupervisors.take(3).map((supervisor) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(supervisor['username'] ?? 'غير معروف'),
                        ],
                      ),
                    )),
              if (assignedSupervisors.length > 3)
                Text(
                  '... و ${assignedSupervisors.length - 3} مشرفين آخرين',
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  static void showAdminSupervisors(
    BuildContext context,
    dynamic admin,
    List<Map<String, dynamic>> assignedSupervisors,
  ) {
    context.showEscDismissibleDialog(
      builder: (dialogContext) => AlertDialog(
        title: Text('مشرفين ${admin.name ?? "المسؤول"}'),
        content: Container(
          width: 400,
          height: 400,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${assignedSupervisors.length} مشرف مُعيّن لهذا المسؤول',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: assignedSupervisors.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 48,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'لا يوجد مشرفين مُعيّنين',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: assignedSupervisors.length,
                        itemBuilder: (context, index) {
                          final supervisor = assignedSupervisors[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF10B981),
                                child: Text(
                                  (supervisor['username'] ?? 'س')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title:
                                  Text(supervisor['username'] ?? 'غير معروف'),
                              subtitle: Text(supervisor['email'] ?? ''),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 