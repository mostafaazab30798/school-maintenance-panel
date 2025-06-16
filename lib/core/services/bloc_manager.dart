import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../logic/blocs/super_admin/super_admin_event.dart';
import 'admin_management_service.dart';

/// Singleton class to manage persistent blocs across navigation
class BlocManager {
  static final BlocManager _instance = BlocManager._internal();
  factory BlocManager() => _instance;
  BlocManager._internal();

  SuperAdminBloc? _superAdminBloc;

  /// Get or create the SuperAdminBloc instance
  SuperAdminBloc getSuperAdminBloc() {
    if (_superAdminBloc == null || _superAdminBloc!.isClosed) {
      final supabase = Supabase.instance.client;
      _superAdminBloc = SuperAdminBloc(
        AdminManagementService(supabase),
        SupervisorRepository(supabase),
        ReportRepository(supabase),
        MaintenanceReportRepository(supabase),
      )..add(LoadSuperAdminData());
    }
    return _superAdminBloc!;
  }

  /// Dispose the SuperAdminBloc when logging out
  void disposeSuperAdminBloc() {
    _superAdminBloc?.close();
    _superAdminBloc = null;
  }

  /// Dispose all blocs
  void disposeAll() {
    disposeSuperAdminBloc();
  }
}
