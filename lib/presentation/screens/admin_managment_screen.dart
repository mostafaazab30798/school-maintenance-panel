import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/admin_management_service.dart';
import '../../data/models/admin.dart';

// BLoC Events
abstract class AdminManagementEvent {}

class LoadAdmins extends AdminManagementEvent {}

class CreateAdmin extends AdminManagementEvent {
  final String name;
  final String email;
  final String authUserId;

  CreateAdmin(
      {required this.name, required this.email, required this.authUserId});
}

class DeleteAdmin extends AdminManagementEvent {
  final String adminId;
  DeleteAdmin(this.adminId);
}

class AssignSupervisors extends AdminManagementEvent {
  final String adminId;
  final List<String> supervisorIds;

  AssignSupervisors({required this.adminId, required this.supervisorIds});
}

// BLoC States
abstract class AdminManagementState {}

class AdminManagementInitial extends AdminManagementState {}

class AdminManagementLoading extends AdminManagementState {}

class AdminManagementLoaded extends AdminManagementState {
  final List<Admin> admins;
  final List<Map<String, dynamic>> unassignedSupervisors;

  AdminManagementLoaded(
      {required this.admins, required this.unassignedSupervisors});
}

class AdminManagementError extends AdminManagementState {
  final String message;
  AdminManagementError(this.message);
}

// BLoC
class AdminManagementBloc
    extends Bloc<AdminManagementEvent, AdminManagementState> {
  final AdminManagementService _adminService;

  AdminManagementBloc(this._adminService) : super(AdminManagementInitial()) {
    on<LoadAdmins>(_onLoadAdmins);
    on<CreateAdmin>(_onCreateAdmin);
    on<DeleteAdmin>(_onDeleteAdmin);
    on<AssignSupervisors>(_onAssignSupervisors);
  }

  Future<void> _onLoadAdmins(
      LoadAdmins event, Emitter<AdminManagementState> emit) async {
    emit(AdminManagementLoading());
    try {
      final admins = await _adminService.getAllAdmins();
      final unassignedSupervisors =
          await _adminService.getUnassignedSupervisors();
      emit(AdminManagementLoaded(
          admins: admins, unassignedSupervisors: unassignedSupervisors));
    } catch (e) {
      emit(AdminManagementError(e.toString()));
    }
  }

  Future<void> _onCreateAdmin(
      CreateAdmin event, Emitter<AdminManagementState> emit) async {
    try {
      await _adminService.createAdmin(
        name: event.name,
        email: event.email,
        authUserId: event.authUserId,
      );
      add(LoadAdmins());
    } catch (e) {
      emit(AdminManagementError(e.toString()));
    }
  }

  Future<void> _onDeleteAdmin(
      DeleteAdmin event, Emitter<AdminManagementState> emit) async {
    try {
      await _adminService.deleteAdmin(event.adminId);
      add(LoadAdmins());
    } catch (e) {
      emit(AdminManagementError(e.toString()));
    }
  }

  Future<void> _onAssignSupervisors(
      AssignSupervisors event, Emitter<AdminManagementState> emit) async {
    try {
      await _adminService.assignSupervisorsToAdmin(
        adminId: event.adminId,
        supervisorIds: event.supervisorIds,
      );
      add(LoadAdmins());
    } catch (e) {
      emit(AdminManagementError(e.toString()));
    }
  }
}

// Main Screen
class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminManagementBloc(
        AdminManagementService(Supabase.instance.client),
      )..add(LoadAdmins()),
      child: const _AdminManagementView(),
    );
  }
}

class _AdminManagementView extends StatelessWidget {
  const _AdminManagementView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المسؤولين'),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateAdminDialog(context),
            ),
          ],
        ),
        body: BlocBuilder<AdminManagementBloc, AdminManagementState>(
          builder: (context, state) {
            if (state is AdminManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AdminManagementError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text('خطأ: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AdminManagementBloc>().add(LoadAdmins()),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (state is AdminManagementLoaded) {
              return _buildAdminsList(context, state);
            }
            return const Center(child: Text('ابدأ بتحميل المسؤولين'));
          },
        ),
      ),
    );
  }

  Widget _buildAdminsList(BuildContext context, AdminManagementLoaded state) {
    if (state.admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('لا يوجد مسؤولين'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCreateAdminDialog(context),
              child: const Text('إضافة مسؤول'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.admins.length,
      itemBuilder: (context, index) {
        final admin = state.admins[index];
        return _AdminCard(
          admin: admin,
          unassignedSupervisors: state.unassignedSupervisors,
        );
      },
    );
  }

  void _showCreateAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AdminManagementBloc>(),
        child: const _CreateAdminDialog(),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Admin admin;
  final List<Map<String, dynamic>> unassignedSupervisors;

  const _AdminCard({
    required this.admin,
    required this.unassignedSupervisors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E88E5),
          child: Text(
            admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(admin.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(admin.email),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 8),
                  Text('تعيين مشرفين')
                ],
              ),
              onTap: () => _showAssignSupervisorsDialog(context),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف')
                ],
              ),
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminManagementService(Supabase.instance.client)
                .getSupervisorsForAdmin(admin.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final supervisors = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المشرفين المعينين (${supervisors.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (supervisors.isEmpty)
                        const Text('لا يوجد مشرفين معينين')
                      else
                        ...supervisors.map((supervisor) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, size: 16),
                                  const SizedBox(width: 8),
                                  Text(supervisor['username'] ?? 'غير معروف'),
                                  const Spacer(),
                                  Text(
                                    supervisor['email'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAssignSupervisorsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AdminManagementBloc>(),
        child: _AssignSupervisorsDialog(
            admin: admin, unassignedSupervisors: unassignedSupervisors),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المسؤول "${admin.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AdminManagementBloc>().add(DeleteAdmin(admin.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _CreateAdminDialog extends StatefulWidget {
  const _CreateAdminDialog();

  @override
  State<_CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<_CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _authUserIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مسؤول جديد'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ملاحظة: يجب إنشاء المستخدم في Supabase Auth أولاً',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المسؤول',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authUserIdController,
                decoration: const InputDecoration(
                  labelText: 'معرف المستخدم من Supabase Auth',
                  border: OutlineInputBorder(),
                  hintText: 'UUID من جدول auth.users',
                ),
                validator: (value) => value?.isEmpty == true ? 'مطلوب' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _createAdmin,
          child: const Text('إنشاء'),
        ),
      ],
    );
  }

  void _createAdmin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AdminManagementBloc>().add(CreateAdmin(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            authUserId: _authUserIdController.text.trim(),
          ));
      Navigator.of(context).pop();
    }
  }
}

class _AssignSupervisorsDialog extends StatefulWidget {
  final Admin admin;
  final List<Map<String, dynamic>> unassignedSupervisors;

  const _AssignSupervisorsDialog({
    required this.admin,
    required this.unassignedSupervisors,
  });

  @override
  State<_AssignSupervisorsDialog> createState() =>
      _AssignSupervisorsDialogState();
}

class _AssignSupervisorsDialogState extends State<_AssignSupervisorsDialog> {
  List<String> selectedSupervisorIds = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعيين مشرفين للمسؤول ${widget.admin.name}'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: widget.unassignedSupervisors.isEmpty
            ? const Center(child: Text('لا يوجد مشرفين غير معينين'))
            : ListView(
                children: widget.unassignedSupervisors.map((supervisor) {
                  final id = supervisor['id'] as String;
                  return CheckboxListTile(
                    title: Text(supervisor['username'] ?? 'غير معروف'),
                    subtitle: Text(supervisor['email'] ?? ''),
                    value: selectedSupervisorIds.contains(id),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          selectedSupervisorIds.add(id);
                        } else {
                          selectedSupervisorIds.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: selectedSupervisorIds.isEmpty
              ? null
              : () {
                  context.read<AdminManagementBloc>().add(AssignSupervisors(
                        adminId: widget.admin.id,
                        supervisorIds: selectedSupervisorIds,
                      ));
                  Navigator.of(context).pop();
                },
          child: Text('تعيين (${selectedSupervisorIds.length})'),
        ),
      ],
    );
  }
}
