import 'package:flutter/material.dart';

/// Utilities for ranking systems and color logic used throughout the app
class RankingUtils {
  
  /// Get rank colors for supervisors based on performance position
  static List<Color> getSupervisorRankColors(int index) {
    switch (index) {
      case 0: // Gold
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 1: // Silver
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 2: // Bronze
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
    }
  }

  /// Get rank colors for admins based on performance position
  static List<Color> getAdminRankColors(int index) {
    switch (index) {
      case 0: // Gold for top admin
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 1: // Silver for second admin
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 2: // Bronze for third admin
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      case 3: // Blue for fourth admin
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
      default:
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
    }
  }

  /// Get rank icon for supervisors based on performance position
  static IconData getSupervisorRankIcon(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events; // Trophy
      case 1:
        return Icons.military_tech; // Medal
      case 2:
        return Icons.star; // Star
      default:
        return Icons.trending_up;
    }
  }

  /// Get rank icon for admins based on performance position
  static IconData getAdminRankIcon(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events; // Trophy
      case 1:
        return Icons.military_tech; // Medal
      case 2:
        return Icons.star; // Star
      case 3:
        return Icons.workspace_premium; // Premium badge
      default:
        return Icons.trending_up;
    }
  }

  /// Get color based on completion rate percentage
  static Color getCompletionRateColor(double rate) {
    if (rate >= 81) return const Color(0xFF10B981); // Green - Excellent
    if (rate >= 61) return const Color(0xFF3B82F6);  // Blue - Good
    if (rate >= 51) return const Color(0xFFF59E0B);  // Orange - Average
    return const Color(0xFFEF4444); // Red - Bad
  }

  /// Get top performing supervisors sorted by completion rate
  static List<Map<String, dynamic>> getTopPerformingSupervisors(
      List<Map<String, dynamic>> supervisors, int count) {
    final sortedSupervisors = List<Map<String, dynamic>>.from(supervisors);
    
    sortedSupervisors.sort((a, b) {
      final aStats = a['stats'] as Map<String, dynamic>;
      final bStats = b['stats'] as Map<String, dynamic>;
      final aCompletionRate = aStats['completion_rate'] as double? ?? 0.0;
      final bCompletionRate = bStats['completion_rate'] as double? ?? 0.0;
      
      return bCompletionRate.compareTo(aCompletionRate);
    });
    
    return sortedSupervisors.take(count).toList();
  }

  /// Get top performing admins sorted by completion rate
  static List<dynamic> getTopPerformingAdmins(
      List<dynamic> admins, Map<String, Map<String, dynamic>> adminStats, int count) {
    final sortedAdmins = List<dynamic>.from(admins);
    
    sortedAdmins.sort((a, b) {
      final aStats = adminStats[a.id] ?? <String, dynamic>{};
      final bStats = adminStats[b.id] ?? <String, dynamic>{};
      
      final aTotalWork = (aStats['reports'] as int? ?? 0) + (aStats['maintenance'] as int? ?? 0);
      final aCompletedWork = (aStats['completed_reports'] as int? ?? 0) + (aStats['completed_maintenance'] as int? ?? 0);
      final aCompletionRate = aTotalWork > 0 ? (aCompletedWork / aTotalWork) : 0.0;
      
      final bTotalWork = (bStats['reports'] as int? ?? 0) + (bStats['maintenance'] as int? ?? 0);
      final bCompletedWork = (bStats['completed_reports'] as int? ?? 0) + (bStats['completed_maintenance'] as int? ?? 0);
      final bCompletionRate = bTotalWork > 0 ? (bCompletedWork / bTotalWork) : 0.0;
      
      return bCompletionRate.compareTo(aCompletionRate);
    });
    
    return sortedAdmins.take(count).toList();
  }

  /// Create a performance ranking badge widget
  static Widget buildPerformanceBadgeForSupervisor(int index) {
    final colors = getSupervisorRankColors(index);
    final icon = getSupervisorRankIcon(index);

    return Positioned(
      top: -8,
      right: -8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 10),
            const SizedBox(width: 3),
            Text(
              '#${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create a performance ranking badge widget for admins
  static Widget buildPerformanceBadgeForAdmin(int index) {
    final colors = getAdminRankColors(index);
    final icon = getAdminRankIcon(index);

    return Positioned(
      top: -8,
      right: -8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 10),
            const SizedBox(width: 3),
            Text(
              '#${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get status colors for different completion states
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'مكتمل':
        return const Color(0xFF10B981);
      case 'pending':
      case 'في الانتظار':
        return const Color(0xFFF59E0B);
      case 'late':
      case 'متأخر':
        return const Color(0xFFEF4444);
      case 'assigned':
      case 'مُعيّن':
        return const Color(0xFF10B981);
      case 'unassigned':
      case 'غير مُعيّن':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Get assignment status text and color
  static ({String text, Color color}) getAssignmentStatus(bool isAssigned) {
    if (isAssigned) {
      return (text: 'مُعيّن', color: const Color(0xFF10B981));
    } else {
      return (text: 'غير مُعيّن', color: const Color(0xFFF59E0B));
    }
  }
} 