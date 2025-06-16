import 'package:flutter/material.dart';

class SupervisorPerformanceCard extends StatelessWidget {
  final Map<String, dynamic> supervisor;

  const SupervisorPerformanceCard({
    super.key,
    required this.supervisor,
  });

  @override
  Widget build(BuildContext context) {
    final username = supervisor['username'] as String? ?? 'غير محدد';
    final email = supervisor['email'] as String? ?? '';
    final totalReports = supervisor['reports_count'] as int? ?? 0;
    final completedReports = supervisor['completed_reports'] as int? ?? 0;
    final totalMaintenance = supervisor['maintenance_count'] as int? ?? 0;
    final completedMaintenance =
        supervisor['completed_maintenance'] as int? ?? 0;

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;
    final completionRate =
        totalWork > 0 ? (completedWork / totalWork * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF334155)
            : const Color(0xFFF8FAFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color:
                      _getCompletionRateColor(completionRate).withOpacity(0.1),
                ),
                child: Text(
                  '${completionRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getCompletionRateColor(completionRate),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStatCard(
                  'بلاغات', totalReports, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _buildMiniStatCard(
                  'صيانة', totalMaintenance, const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _buildMiniStatCard(
                  'مكتمل', completedWork, const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 80) return const Color(0xFF10B981);
    if (rate >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildMiniStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
