import 'package:flutter/material.dart';

class AdminGroupStatsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> supervisors;
  final bool isUnassigned;

  const AdminGroupStatsWidget({
    super.key,
    required this.supervisors,
    required this.isUnassigned,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate group statistics
    final stats = _calculateGroupStats();
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Total Supervisors
          Expanded(
            child: _buildStatItem(
              'إجمالي المشرفين',
              '${supervisors.length}',
              Icons.people,
              const Color(0xFF3B82F6),
            ),
          ),
          
          // Total Reports
          Expanded(
            child: _buildStatItem(
              'إجمالي البلاغات',
              '${stats['totalReports']}',
              Icons.report,
              const Color(0xFFF59E0B),
            ),
          ),
          
          // Total Maintenance
          Expanded(
            child: _buildStatItem(
              'إجمالي الصيانة',
              '${stats['totalMaintenance']}',
              Icons.build,
              const Color(0xFFEF4444),
            ),
          ),
          
          // Average Completion Rate
          Expanded(
            child: _buildStatItem(
              'متوسط الإنجاز',
              '${stats['avgCompletionRate'].toStringAsFixed(0)}%',
              Icons.trending_up,
              const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateGroupStats() {
    int totalReports = 0;
    int totalMaintenance = 0;
    int totalCompleted = 0;
    int totalWork = 0;
    
    for (final supervisor in supervisors) {
      final stats = supervisor['stats'] as Map<String, dynamic>;
      final reports = stats['reports'] as int? ?? 0;
      final maintenance = stats['maintenance'] as int? ?? 0;
      final completedReports = stats['completed_reports'] as int? ?? 0;
      final completedMaintenance = stats['completed_maintenance'] as int? ?? 0;
      
      totalReports += reports;
      totalMaintenance += maintenance;
      totalCompleted += (completedReports + completedMaintenance);
      totalWork += (reports + maintenance);
    }
    
    final avgCompletionRate = totalWork > 0 ? (totalCompleted / totalWork * 100) : 0.0;
    
    return {
      'totalReports': totalReports,
      'totalMaintenance': totalMaintenance,
      'totalCompleted': totalCompleted,
      'totalWork': totalWork,
      'avgCompletionRate': avgCompletionRate,
    };
  }
} 