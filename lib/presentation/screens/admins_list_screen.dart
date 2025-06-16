import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/admin.dart';
import '../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../logic/blocs/super_admin/super_admin_event.dart';
import '../../logic/blocs/super_admin/super_admin_state.dart';
import '../widgets/common/esc_dismissible_dialog.dart';
import '../../core/services/admin_management_service.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../widgets/admins_list/admins_list_content.dart';

class AdminsListScreen extends StatelessWidget {
  const AdminsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BlocProvider(
      create: (context) => SuperAdminBloc(
        AdminManagementService(supabase),
        SupervisorRepository(supabase),
        ReportRepository(supabase),
        MaintenanceReportRepository(supabase),
      )..add(LoadSuperAdminData()),
      child: const _AdminsListView(),
    );
  }
}

class _AdminsListView extends StatelessWidget {
  const _AdminsListView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
          title: BlocBuilder<SuperAdminBloc, SuperAdminState>(
            builder: (context, state) {
              final adminCount = state is SuperAdminLoaded 
                  ? state.admins.where((a) => a.role == 'admin').length
                  : 0;
              
              return Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, size: 24),
                  const SizedBox(width: 8),
                  const Text('قائمة المسؤولين'),
                  const SizedBox(width: 8),
          Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Text(
                      '$adminCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                        ),
                      ),
                    ],
              );
            },
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          
        ),
        body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
            ),
          ),
          child: BlocBuilder<SuperAdminBloc, SuperAdminState>(
            builder: (context, state) {
              if (state is SuperAdminLoading) {
                return const Center(
      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
        children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                    SizedBox(height: 16),
                    Text(
                        'جاري تحميل قائمة المسؤولين...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
              } else if (state is SuperAdminError) {
    return Center(
      child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                boxShadow: [
                  BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
        Container(
                          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red[600],
                          ),
                        ),
                  const SizedBox(height: 16),
              Text(
                          'حدث خطأ',
              style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(height: 8),
            Text(
                          state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
            fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context
                              .read<SuperAdminBloc>()
                              .add(LoadSuperAdminData(forceRefresh: true)),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
          ),
        ),
      ],
        ),
      ),
    );
              } else if (state is SuperAdminLoaded) {
                return AdminsListContent(
                  admins: state.admins.where((a) => a.role == 'admin').toList(),
                  adminStats: state.adminStats,
                  allSupervisors: state.allSupervisors,
                  supervisorsWithStats: state.supervisorsWithStats,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
