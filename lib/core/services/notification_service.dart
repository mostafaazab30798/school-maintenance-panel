import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// Centralized notification service for handling FCM notifications
/// 
/// This service:
/// - Manages FCM token registration/storage
/// - Sends notifications via Edge Function
/// - Prevents duplicate notifications
/// - Handles supervisor validation
/// - Provides comprehensive error handling
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  final SupabaseClient _client = Supabase.instance.client;
  
  // Track recent notifications to prevent duplicates
  final Set<String> _recentNotifications = {};
  Timer? _cleanupTimer;

  /// Initialize notification service
  void initialize() {
    // Clean up recent notifications every 5 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _recentNotifications.clear();
      if (kDebugMode) {
        debugPrint('NotificationService: Cleaned up recent notifications');
      }
    });
  }

  /// Dispose notification service
  void dispose() {
    _cleanupTimer?.cancel();
    _recentNotifications.clear();
  }

  /// Store FCM token for current user
  Future<bool> storeFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      // Upsert the FCM token
      await _client.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': fcmToken,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('NotificationService: FCM token stored for user: $userId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Failed to store FCM token: $e');
      }
      return false;
    }
  }

  /// Send notification to supervisor for a report
  Future<NotificationResult> sendReportNotification({
    required String supervisorId,
    required String reportId,
    required String schoolName,
    required String priority,
    String? description,
    bool isMaintenance = false,
    bool isEmergency = false,
  }) async {
    // 🚀 Enhanced parameter validation
    if (supervisorId.isEmpty) {
      return NotificationResult.error('supervisorId cannot be empty');
    }
    if (reportId.isEmpty) {
      return NotificationResult.error('reportId cannot be empty');
    }
    if (schoolName.isEmpty) {
      return NotificationResult.error('schoolName cannot be empty');
    }
    if (priority.isEmpty) {
      return NotificationResult.error('priority cannot be empty');
    }

    // Create unique identifier for this notification
    final notificationKey = '${supervisorId}_${reportId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Check for recent duplicates
    if (_recentNotifications.contains(notificationKey)) {
      if (kDebugMode) {
        debugPrint('NotificationService: Skipping duplicate notification: $notificationKey');
      }
      return NotificationResult.duplicate(
        'Duplicate notification prevented',
        supervisorId: supervisorId,
      );
    }

    // Add to recent notifications
    _recentNotifications.add(notificationKey);

    try {
      // Determine notification content based on report type
      final String title;
      final String body;
      final String notificationType;

      if (isMaintenance) {
        title = '🔧 بلاغ صيانة جديد';
        body = 'لديك طلب صيانة جديد في $schoolName';
        notificationType = 'maintenance';
      } else {
        title = isEmergency ? '🚨 بلاغ طارئ' : '📋 بلاغ جديد';
        body = 'لديك بلاغ جديد في $schoolName';
        notificationType = isEmergency ? 'emergency' : 'new_report';
      }

      // Prepare notification data
      final notificationData = {
        'user_id': supervisorId,
        'title': title,
        'body': body,
        'priority': priority,
        'school_name': schoolName,
        'data': {
          'type': notificationType,
          'report_id': reportId,
          'school_name': schoolName,
          'description': description ?? '',
          'priority': priority,
          'is_emergency': isEmergency,
          'is_maintenance': isMaintenance,
        }
      };

      if (kDebugMode) {
        debugPrint('NotificationService: Sending notification to supervisor: $supervisorId');
        debugPrint('NotificationService: Notification type: $notificationType');
      }

      // Send notification via Edge Function
      final response = await _client.functions
          .invoke('send_notification', body: notificationData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Notification request timed out');
            },
          );

      if (response.status == 200) {
        final data = response.data;
        if (kDebugMode) {
          debugPrint('NotificationService: Notification sent successfully');
          debugPrint('NotificationService: Response: $data');
          
          // Enhanced debugging for notification delivery
          final results = data?['results'] as List?;
          if (results != null) {
            for (int i = 0; i < results.length; i++) {
              final result = results[i];
              if (result['success'] == true) {
                debugPrint('✅ Token ${i + 1}: Delivered successfully (${result['messageId']})');
              } else {
                debugPrint('❌ Token ${i + 1}: Failed - ${result['error']}');
                debugPrint('   📱 Token: ${result['token']}');
              }
            }
          }
        }
        
        return NotificationResult.success(
          'Notification sent successfully',
          supervisorId: supervisorId,
          messageId: data?['results']?.first?['messageId'],
          tokensFound: data?['tokensFound'] ?? 0,
        );
      } else {
        final error = response.data?['error'] ?? 'Unknown error';
        if (kDebugMode) {
          debugPrint('NotificationService: Notification failed: $error');
        }
        
        return NotificationResult.error(
          error,
          supervisorId: supervisorId,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Exception sending notification: $e');
        
        // Provide more specific error guidance
        if (e.toString().contains('Failed to fetch')) {
          debugPrint('🚨 EDGE FUNCTION ERROR: The send_notification Edge Function is not deployed!');
          debugPrint('📋 To fix this issue:');
          debugPrint('   1. Run: npx supabase login');
          debugPrint('   2. Run: npx supabase link --project-ref cftjaukrygtzguqcafon');
          debugPrint('   3. Run: npx supabase functions deploy send_notification');
          debugPrint('   4. Set FIREBASE_SERVICE_ACCOUNT and FIREBASE_PROJECT_ID in Supabase Dashboard');
        }
      }
      
      String errorMessage = e.toString();
      if (e.toString().contains('Failed to fetch')) {
        errorMessage = 'Edge Function not deployed. Please deploy send_notification function to Supabase.';
      }
      
      return NotificationResult.error(
        errorMessage,
        supervisorId: supervisorId,
      );
    }
  }

  /// Send notifications for multiple reports (bulk submission)
  Future<List<NotificationResult>> sendBulkReportNotifications({
    required List<Map<String, dynamic>> reports,
    bool isMaintenance = false,
  }) async {
    final results = <NotificationResult>[];
    
    if (kDebugMode) {
      debugPrint('NotificationService: Sending ${reports.length} bulk notifications');
      debugPrint('NotificationService: isMaintenance: $isMaintenance');
      if (reports.isNotEmpty) {
        debugPrint('NotificationService: Sample report structure: ${reports.first.keys.toList()}');
      }
    }

    // Validate input
    if (reports.isEmpty) {
      if (kDebugMode) {
        debugPrint('NotificationService: No reports to process');
      }
      return results;
    }

    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      
      try {
        // 🚀 Enhanced null safety for all required parameters
        final supervisorId = report['supervisor_id']?.toString();
        final reportId = report['id']?.toString();
        final schoolName = report['school_name']?.toString() ?? 'مدرسة غير معروفة';
        final priority = report['priority']?.toString() ?? 'عادي';
        final description = report['description']?.toString();

        // Validate required parameters
        if (supervisorId == null || supervisorId.isEmpty) {
          throw ArgumentError('supervisor_id is required but was null or empty');
        }
        if (reportId == null || reportId.isEmpty) {
          throw ArgumentError('report id is required but was null or empty');
        }

        if (kDebugMode) {
          debugPrint('NotificationService: Processing notification ${i + 1}/${reports.length}');
          debugPrint('  supervisorId: $supervisorId');
          debugPrint('  reportId: $reportId');
          debugPrint('  schoolName: $schoolName');
          debugPrint('  priority: $priority');
          debugPrint('  isMaintenance: $isMaintenance');
        }

        final result = await sendReportNotification(
          supervisorId: supervisorId,
          reportId: reportId,
          schoolName: schoolName,
          priority: priority,
          description: description,
          isMaintenance: isMaintenance,
          isEmergency: !isMaintenance && 
                      (priority.toLowerCase() == 'high' || 
                       priority.toLowerCase() == 'emergency'),
        );
        
        results.add(result);
        
        // Small delay between notifications to prevent overwhelming the server
        if (i < reports.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NotificationService: Error in bulk notification ${i + 1}: $e');
        }
        
        // Enhanced error logging with report context
        final errorSupervisorId = report['supervisor_id']?.toString() ?? 'unknown';
        if (kDebugMode) {
          debugPrint('NotificationService: Full report data: $report');
          debugPrint('NotificationService: Error details: $e');
        }
        
        results.add(NotificationResult.error(
          'Error for report ${report['id'] ?? 'unknown'}: ${e.toString()}',
          supervisorId: errorSupervisorId,
        ));
      }
    }

    final successCount = results.where((r) => r.isSuccess).length;
    if (kDebugMode) {
      debugPrint('NotificationService: Bulk notifications complete: $successCount/${reports.length} successful');
    }

    return results;
  }

  /// Verify supervisor exists before sending notification
  Future<bool> verifySupervisor(String supervisorId) async {
    try {
      final response = await _client
          .from('supervisors')
          .select('id')
          .eq('id', supervisorId)
          .single();
      
      return response != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Supervisor verification failed: $e');
      }
      return false;
    }
  }

  /// Get notification statistics
  Future<NotificationStats> getNotificationStats() async {
    try {
      // Get total tokens
      final tokensResponse = await _client
          .from('user_fcm_tokens')
          .select('user_id')
          .count(CountOption.exact);

      // Get supervisors with tokens
      final supervisorsWithTokensResponse = await _client
          .from('user_fcm_tokens')
          .select('user_id');

      final uniqueSupervisors = supervisorsWithTokensResponse
          .map((e) => e['user_id'])
          .toSet()
          .length;

      return NotificationStats(
        totalTokens: tokensResponse.count,
        supervisorsWithTokens: uniqueSupervisors,
        recentNotifications: _recentNotifications.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Failed to get stats: $e');
      }
      return NotificationStats(
        totalTokens: 0,
        supervisorsWithTokens: 0,
        recentNotifications: _recentNotifications.length,
      );
    }
  }
}

/// Result of a notification operation
class NotificationResult {
  final bool isSuccess;
  final bool isDuplicate;
  final String message;
  final String? supervisorId;
  final String? messageId;
  final int? tokensFound;

  const NotificationResult._({
    required this.isSuccess,
    required this.isDuplicate,
    required this.message,
    this.supervisorId,
    this.messageId,
    this.tokensFound,
  });

  factory NotificationResult.success(
    String message, {
    String? supervisorId,
    String? messageId,
    int? tokensFound,
  }) {
    return NotificationResult._(
      isSuccess: true,
      isDuplicate: false,
      message: message,
      supervisorId: supervisorId,
      messageId: messageId,
      tokensFound: tokensFound,
    );
  }

  factory NotificationResult.error(
    String message, {
    String? supervisorId,
  }) {
    return NotificationResult._(
      isSuccess: false,
      isDuplicate: false,
      message: message,
      supervisorId: supervisorId,
    );
  }

  factory NotificationResult.duplicate(
    String message, {
    String? supervisorId,
  }) {
    return NotificationResult._(
      isSuccess: false,
      isDuplicate: true,
      message: message,
      supervisorId: supervisorId,
    );
  }

  @override
  String toString() {
    return 'NotificationResult(isSuccess: $isSuccess, isDuplicate: $isDuplicate, message: $message)';
  }
}

/// Notification service statistics
class NotificationStats {
  final int totalTokens;
  final int supervisorsWithTokens;
  final int recentNotifications;

  const NotificationStats({
    required this.totalTokens,
    required this.supervisorsWithTokens,
    required this.recentNotifications,
  });

  @override
  String toString() {
    return 'NotificationStats(totalTokens: $totalTokens, supervisorsWithTokens: $supervisorsWithTokens, recentNotifications: $recentNotifications)';
  }
} 