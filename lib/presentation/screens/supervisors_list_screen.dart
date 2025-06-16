import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/admin_management_service.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../logic/blocs/super_admin/super_admin_state.dart';
import '../../logic/blocs/super_admin/super_admin_event.dart';
import '../widgets/supervisors_list/supervisors_list_content.dart';

class SupervisorsListScreen extends StatelessWidget {
  const SupervisorsListScreen({super.key});

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
      child: const _SupervisorsListView(),
    );
  }
}

class _SupervisorsListView extends StatelessWidget {
  const _SupervisorsListView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'قائمة المشرفين',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1E293B),
          elevation: 0,
          
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_rounded,
                      color: const Color(0xFF10B981),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    BlocBuilder<SuperAdminBloc, SuperAdminState>(
                      builder: (context, state) {
                        if (state is SuperAdminLoaded) {
                          return Text(
                            '${state.allSupervisors.length} مشرف',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text(
                          '0 مشرف',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<SuperAdminBloc, SuperAdminState>(
          builder: (context, state) {
            if (state is SuperAdminLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل قائمة المشرفين...',
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
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is SuperAdminLoaded) {
              return SupervisorsListContent(
                supervisorsWithStats: state.supervisorsWithStats,
                admins: state.admins,
              );
            }
            return const Center(
              child: Text(
                'مرحباً بك في قائمة المشرفين',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 