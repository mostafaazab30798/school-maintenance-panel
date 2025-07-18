import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/admin_management_service.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../widgets/common/shared_app_bar.dart';
import '../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../logic/blocs/super_admin/super_admin_state.dart';
import '../../logic/blocs/super_admin/super_admin_event.dart';
import '../widgets/supervisors_list/supervisors_list_content.dart';
import '../widgets/common/standard_refresh_button.dart';
import 'dart:ui';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: SharedAppBar(
          title: 'قائمة المشرفين',
          actions: [
            StandardRefreshButton(
              onPressed: () => context
                  .read<SuperAdminBloc>()
                  .add(LoadSuperAdminData(forceRefresh: true)),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            BlocBuilder<SuperAdminBloc, SuperAdminState>(
              builder: (context, state) => switch (state) {
                SuperAdminLoading() => _buildLoading(context, isDark),
                SuperAdminError() => _buildError(context, isDark, state.message),
                SuperAdminLoaded() => _buildContent(context, state),
                _ => const SliverToBoxAdapter(child: SizedBox()),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, bool isDark) {
    return SliverFillRemaining(
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
              'جاري تحميل قائمة المشرفين...',
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
    return SliverFillRemaining(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                message,
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
      ),
    );
  }

  Widget _buildContent(BuildContext context, SuperAdminLoaded state) {
    return SliverToBoxAdapter(
      child: SupervisorsListContent(
        supervisorsWithStats: state.supervisorsWithStats,
        admins: state.admins,
      ),
    );
  }
}


