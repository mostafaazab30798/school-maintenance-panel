import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../core/services/supabase_storage_service.dart';

import '../../logic/blocs/maintenance_reports/maintenance_bloc.dart';
import '../../logic/blocs/maintenance_reports/maintenance_event.dart';
import '../../logic/blocs/maintenance_reports/maintenance_state.dart';
import '../../logic/blocs/maintenance_form/maintenance_form_bloc.dart';
import '../../logic/blocs/maintenance_form/maintenance_form_event.dart';
import '../../logic/blocs/maintenance_form/maintenance_form_state.dart';
import '../widgets/common/searchable_school_dropdown.dart';

class AddMultipleMaintenanceScreen extends StatelessWidget {
  final String supervisorId;

  const AddMultipleMaintenanceScreen({
    super.key,
    required this.supervisorId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MaintenanceFormBloc(
        storageService: context.read<SupabaseStorageService>(),
      ),
      child: _MaintenanceFormContent(supervisorId: supervisorId),
    );
  }
}

class _MaintenanceFormContent extends StatefulWidget {
  final String supervisorId;

  const _MaintenanceFormContent({required this.supervisorId});

  @override
  State<_MaintenanceFormContent> createState() =>
      _MaintenanceFormContentState();
}

class _MaintenanceFormContentState extends State<_MaintenanceFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _schoolNameController;
  late final TextEditingController _notesController;
  String? _selectedDate;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _schoolNameController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearFormFields(BuildContext context) {
    _schoolNameController.clear();
    _notesController.clear();
    setState(() {
      _selectedDate = null;
    });
    _formKey.currentState?.reset();
    context.read<MaintenanceFormBloc>().add(const MaintenanceFormCleared());
  }

  void _pickImages(BuildContext context) {
    context.read<MaintenanceFormBloc>().add(const ImagesPickRequested());
  }

  void _removeImage(BuildContext context, String url) {
    context.read<MaintenanceFormBloc>().add(ImageRemoved(url));
  }

  void _submitMaintenance(BuildContext context, MaintenanceFormState state) {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (state.isValid) {
        context.read<MaintenanceReportBloc>().add(
              SubmitMaintenanceReport(
                supervisorId: widget.supervisorId,
                schoolName: state.schoolName!,
                notes: state.notes!,
                scheduledDate: state.scheduledDate!,
                imageUrls: state.imageUrls,
              ),
            );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('يرجى ملء جميع الحقول المطلوبة',
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        appBar: _buildModernAppBar(context),
        body: MultiBlocListener(
          listeners: [
            BlocListener<MaintenanceReportBloc, MaintenanceReportState>(
              listener: (context, state) {
                if (state is MaintenanceReportLoading) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                } else {
                  Navigator.of(context, rootNavigator: true).maybePop();
                }

                if (state is MaintenanceReportSuccess) {
                  _clearFormFields(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('تم إرسال الصيانة بنجاح',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(12),
                    ),
                  );
                  Navigator.pop(context);
                } else if (state is MaintenanceReportFailure) {
                  print(state.error);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text('خطأ: ${state.error}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13))),
                        ],
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(12),
                    ),
                  );
                }
              },
            ),
            BlocListener<MaintenanceFormBloc, MaintenanceFormState>(
              listener: (context, state) {
                if (state.isUploadingImages) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)),
                          ),
                          SizedBox(width: 6),
                          Text('جاري رفع الصور...',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                        ],
                      ),
                      backgroundColor: const Color(0xFF3B82F6),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(12),
                    ),
                  );
                }

                if (state.schoolName != _schoolNameController.text) {
                  _schoolNameController.text = state.schoolName ?? '';
                }

                if (state.notes != _notesController.text) {
                  _notesController.text = state.notes ?? '';
                }

                if (state.scheduledDate != _selectedDate) {
                  setState(() {
                    _selectedDate = state.scheduledDate;
                  });
                }
              },
            ),
          ],
          child: BlocBuilder<MaintenanceFormBloc, MaintenanceFormState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  // Header Statistics
                  SliverToBoxAdapter(
                    child: _buildHeaderStats(context),
                  ),

                  // Maintenance Form Card
                  SliverToBoxAdapter(
                    child: _buildMaintenanceCard(context, state),
                  ),

                  // Action Button
                  SliverToBoxAdapter(
                    child: _buildActionButton(context, state),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 60),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: true,
      title: Text(
        'إضافة صيانة دورية',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          fontSize: 17,
          letterSpacing: -0.2,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F172A).withOpacity(0.95),
                    const Color(0xFF0F172A).withOpacity(0.8),
                  ]
                : [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.8),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.white;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withOpacity(0.9),
            cardColor.withOpacity(0.7),
          ],
        ),
        border: Border.all(
          color: borderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.2),
                  const Color(0xFF10B981).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.build_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صيانة دورية جديدة',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'املأ البيانات المطلوبة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(
      BuildContext context, MaintenanceFormState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor.withOpacity(0.95),
                cardColor.withOpacity(0.85),
              ],
            ),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : borderColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981)
                    .withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 20 : 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              if (isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  _buildCardHeader(context),
                  _buildFormFields(context, state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.2),
                  const Color(0xFF10B981).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Color(0xFF10B981),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تفاصيل الصيانة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, MaintenanceFormState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSchoolNameField(context),
            const SizedBox(height: 12),
            _buildScheduledDateField(context),
            const SizedBox(height: 12),
            _buildNotesField(context),
            const SizedBox(height: 12),
            _buildImageUploadSection(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolNameField(BuildContext context) {
    return BlocBuilder<MaintenanceFormBloc, MaintenanceFormState>(
      builder: (context, state) {
        return SearchableSchoolDropdown(
          supervisorId: widget.supervisorId,
          selectedSchoolName: state.schoolName,
          hintText: 'ابحث واختر المدرسة...',
          errorText: state.hasInteractedWithForm && 
                    (state.schoolName == null || state.schoolName!.isEmpty)
              ? 'يرجى اختيار المدرسة'
              : null,
          onSchoolSelected: (schoolName) {
            print('🏫 Maintenance form received school: $schoolName');
            context
                .read<MaintenanceFormBloc>()
                .add(SchoolNameChanged(schoolName));
          },
        );
      },
    );
  }

  Widget _buildScheduledDateField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'تاريخ الصيانة',
          labelStyle: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.schedule_rounded,
            color: Color(0xFF3B82F6),
            size: 16,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
        value: _selectedDate,
        items: _buildScheduleDropdownItems(),
        onChanged: (val) {
          setState(() {
            _selectedDate = val;
          });
          context
              .read<MaintenanceFormBloc>()
              .add(ScheduledDateChanged(val ?? ''));
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى اختيار تاريخ الصيانة';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'ملاحظات',
          labelStyle: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.description_rounded,
            color: Color(0xFF8B5CF6),
            size: 16,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
        ),
        controller: _notesController,
        onChanged: (value) =>
            context.read<MaintenanceFormBloc>().add(NotesChanged(value)),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى إدخال ملاحظات';
          }
          return null;
        },
        maxLines: 2,
      ),
    );
  }

  Widget _buildImageUploadSection(
      BuildContext context, MaintenanceFormState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.1),
            const Color(0xFFF59E0B).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'الصور المرفقة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF59E0B),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: state.isUploadingImages
                        ? null
                        : () => _pickImages(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          state.isUploadingImages
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate_rounded,
                                  color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          const Text(
                            'إرفاق صور',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (state.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${state.imageUrls.length} صورة مرفقة',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: state.imageUrls.map<Widget>((url) {
                final name = Uri.parse(url).pathSegments.last;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_rounded,
                        size: 12,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeImage(context, url),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 12,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, MaintenanceFormState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF10B981),
              Color(0xFF059669),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _submitMaintenance(context, state),
            borderRadius: BorderRadius.circular(12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'إرسال الصيانة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildScheduleDropdownItems() {
    return [
      _buildDropdownItem('today', 'اليوم'),
      _buildDropdownItem('tomorrow', 'غداً'),
      _buildDropdownItem('after_tomorrow', 'بعد غد'),
    ];
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label) {
    return DropdownMenuItem(
      value: value,
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          );
        },
      ),
    );
  }
}
