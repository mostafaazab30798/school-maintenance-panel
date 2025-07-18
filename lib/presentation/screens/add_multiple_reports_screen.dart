import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';

import '../../core/constants/app_fonts.dart';
import '../../logic/blocs/multi_reports/multi_reports_bloc.dart';
import '../../logic/blocs/multi_reports/multi_reports_event.dart';
import '../../logic/blocs/multi_reports/multi_reports_state.dart';
import '../../logic/cubits/add_multiple_reports_cubit.dart';
import '../../logic/cubits/add_multiple_reports_state.dart';
import '../widgets/common/searchable_school_dropdown.dart';

class AddMultipleReportsScreen extends StatelessWidget {
  final String supervisorId;
  const AddMultipleReportsScreen({super.key, required this.supervisorId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<MultipleReportBloc, MultipleReportState>(
        listener: (context, state) {
          if (state is MultipleReportsSuccess) {
            context.read<AddMultipleReportsCubit>().clearAllReports();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('تم رفع البلاغات بنجاح',
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
          } else if (state is MultipleReportsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text('فشل رفع البلاغات: ${state.error}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 13))),
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
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          appBar: _buildModernAppBar(context),
          body: BlocBuilder<AddMultipleReportsCubit, AddMultipleReportsState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  // Validation Error Message
                  if (state.validationFailed)
                    SliverToBoxAdapter(
                      child: _buildValidationError(context),
                    ),

                  // Header Statistics
                  SliverToBoxAdapter(
                    child: _buildHeaderStats(context, state),
                  ),

                  // Reports List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == state.reports.length) {
                            return _buildActionButtons(context, state);
                          }
                          return _ModernReportCard(
                            key: ValueKey(
                                '${state.reports[index].supervisorId}-$index-${state.reports[index].hashCode}'),
                            index: index,
                          );
                        },
                        childCount: state.reports.length + 1,
                      ),
                    ),
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
        'إضافة بلاغات متعددة',
        style: AppFonts.appBarTitle(isDark: isDark),
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

  Widget _buildValidationError(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF4444).withOpacity(0.1),
            const Color(0xFFEF4444).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'يرجى ملء جميع الحقول المطلوبة قبل الإرسال',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(
      BuildContext context, AddMultipleReportsState state) {
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
            color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                  const Color(0xFF3B82F6).withOpacity(0.2),
                  const Color(0xFF3B82F6).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البلاغات المُضافة',
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
                  '${state.reports.length} بلاغ',
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

  Widget _buildActionButtons(
      BuildContext context, AddMultipleReportsState state) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Add New Report Button
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF3B82F6).withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context
                    .read<AddMultipleReportsCubit>()
                    .addReport(supervisorId),
                borderRadius: BorderRadius.circular(12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                        color: Color(0xFF3B82F6), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'إضافة بلاغ جديد',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Submit All Reports Button
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: state.reports.isEmpty
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF94A3B8).withOpacity(0.3),
                        const Color(0xFF94A3B8).withOpacity(0.1),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                    ),
              border: Border.all(
                color: state.reports.isEmpty
                    ? const Color(0xFF94A3B8).withOpacity(0.3)
                    : const Color(0xFF10B981).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: state.reports.isEmpty
                  ? null
                  : [
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
                onTap: state.reports.isEmpty
                    ? null
                    : () => context
                            .read<AddMultipleReportsCubit>()
                            .submitReports((reports) {
                          if (reports.isNotEmpty) {
                            context
                                .read<MultipleReportBloc>()
                                .add(SubmitMultipleReports(reports));
                          }
                        }),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.isSubmitting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else ...[
                      Icon(
                        Icons.cloud_upload_rounded,
                        color: state.reports.isEmpty
                            ? const Color(0xFF94A3B8)
                            : Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'رفع البلاغات',
                        style: TextStyle(
                          color: state.reports.isEmpty
                              ? const Color(0xFF94A3B8)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernReportCard extends StatefulWidget {
  final int index;

  const _ModernReportCard({super.key, required this.index});

  @override
  State<_ModernReportCard> createState() => _ModernReportCardState();
}

class _ModernReportCardState extends State<_ModernReportCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.white;

    final cubit = context.read<AddMultipleReportsCubit>();
    final data = cubit.state.reports[widget.index];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
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
                  ? const Color(0xFF3B82F6).withOpacity(0.3)
                  : borderColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6)
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
                  _buildCardHeader(context, cubit, isDark),
                  _buildFormFields(context, cubit, data, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(
      BuildContext context, AddMultipleReportsCubit cubit, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF3B82F6).withOpacity(0.05),
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
                  const Color(0xFF3B82F6).withOpacity(0.2),
                  const Color(0xFF3B82F6).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.report_rounded,
              color: Color(0xFF3B82F6),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'البلاغ ${widget.index + 1}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFEF4444).withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => cubit.removeReport(widget.index),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 16,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                padding: const EdgeInsets.all(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, AddMultipleReportsCubit cubit,
      dynamic data, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSchoolNameField(context, cubit, data, isDark),
          const SizedBox(height: 12),
          _buildDescriptionField(context, cubit, data, isDark),
          const SizedBox(height: 12),
          _buildTypeField(context, cubit, data, isDark),
          const SizedBox(height: 12),
          _buildReportSourceField(context, cubit, data, isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildPriorityField(context, cubit, data, isDark)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildScheduleField(context, cubit, data, isDark)),
            ],
          ),
          const SizedBox(height: 12),
          _buildImageUploadSection(context, cubit, data, isDark),
        ],
      ),
    );
  }

  Widget _buildSchoolNameField(BuildContext context,
      AddMultipleReportsCubit cubit, dynamic data, bool isDark) {
    return BlocBuilder<AddMultipleReportsCubit, AddMultipleReportsState>(
      buildWhen: (previous, current) =>
          previous.validationFailed != current.validationFailed ||
          previous.reports != current.reports,
      builder: (context, state) {
        return SearchableSchoolDropdown(
          supervisorId: data.supervisorId ?? '',
          selectedSchoolName: data.schoolName,
          hintText: 'ابحث واختر المدرسة...',
          errorText: state.validationFailed &&
                  (data.schoolName == null || data.schoolName!.isEmpty)
              ? 'اسم المدرسة مطلوب'
              : null,
          onSchoolSelected: (schoolName) {
            print('🏫 Screen: onSchoolSelected called with: $schoolName');
            cubit.updateSchoolName(widget.index, schoolName);
          },
        );
      },
    );
  }

  Widget _buildDescriptionField(BuildContext context,
      AddMultipleReportsCubit cubit, dynamic data, bool isDark) {
    return BlocBuilder<AddMultipleReportsCubit, AddMultipleReportsState>(
      buildWhen: (previous, current) =>
          previous.validationFailed != current.validationFailed,
      builder: (context, state) {
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
              labelText: 'وصف البلاغ',
              labelStyle: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
              errorText: state.validationFailed &&
                      (data.description == null || data.description!.isEmpty)
                  ? 'وصف البلاغ مطلوب'
                  : null,
              errorStyle: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            initialValue: data.description,
            maxLines: 2,
            onChanged: (val) => cubit.updateDescription(widget.index, val),
          ),
        );
      },
    );
  }

  Widget _buildTypeField(BuildContext context, AddMultipleReportsCubit cubit,
      dynamic data, bool isDark) {
    return BlocBuilder<AddMultipleReportsCubit, AddMultipleReportsState>(
      buildWhen: (previous, current) =>
          previous.validationFailed != current.validationFailed,
      builder: (context, state) {
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
              labelText: 'نوع البلاغ',
              labelStyle: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.category_rounded,
                color: Color(0xFF06B6D4),
                size: 16,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              errorText: state.validationFailed &&
                      (data.type == null || data.type!.isEmpty)
                  ? 'نوع البلاغ مطلوب'
                  : null,
              errorStyle: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            value: data.type?.isEmpty ?? true ? null : data.type,
            onChanged: (val) => cubit.updateType(widget.index, val ?? ''),
            items: _buildTypeDropdownItems(),
          ),
        );
      },
    );
  }

  Widget _buildReportSourceField(BuildContext context,
      AddMultipleReportsCubit cubit, dynamic data, bool isDark) {
    return BlocBuilder<AddMultipleReportsCubit, AddMultipleReportsState>(
      buildWhen: (previous, current) =>
          previous.validationFailed != current.validationFailed,
      builder: (context, state) {
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
              labelText: 'مصدر البلاغ',
              labelStyle: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.source_rounded,
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
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            value:
                data.reportSource?.isEmpty ?? true ? null : data.reportSource,
            onChanged: (val) =>
                cubit.updateReportSource(widget.index, val ?? 'unifier'),
            items: _buildReportSourceDropdownItems(),
          ),
        );
      },
    );
  }

  Widget _buildPriorityField(BuildContext context,
      AddMultipleReportsCubit cubit, dynamic data, bool isDark) {
    return BlocBuilder<AddMultipleReportsCubit, AddMultipleReportsState>(
      buildWhen: (previous, current) =>
          previous.validationFailed != current.validationFailed,
      builder: (context, state) {
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
              labelText: 'الأولوية',
              labelStyle: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.priority_high_rounded,
                color: Color(0xFFEF4444),
                size: 16,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              errorText: state.validationFailed &&
                      (data.priority == null || data.priority!.isEmpty)
                  ? 'الأولوية مطلوبة'
                  : null,
              errorStyle: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            value: data.priority?.isEmpty ?? true ? null : data.priority,
            onChanged: (val) => cubit.updatePriority(widget.index, val ?? ''),
            items: _buildPriorityDropdownItems(),
          ),
        );
      },
    );
  }

  Widget _buildScheduleField(BuildContext context,
      AddMultipleReportsCubit cubit, dynamic data, bool isDark) {
    return BlocBuilder<AddMultipleReportsCubit, AddMultipleReportsState>(
      buildWhen: (previous, current) =>
          previous.validationFailed != current.validationFailed,
      builder: (context, state) {
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
              labelText: 'الجدولة',
              labelStyle: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF059669),
                size: 16,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              errorText: state.validationFailed &&
                      (data.scheduledDate == null ||
                          data.scheduledDate!.isEmpty)
                  ? 'الجدولة مطلوبة'
                  : null,
              errorStyle: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            value: data.scheduledDate?.isEmpty ?? true
                ? null
                : (data.scheduledDate == 'today' ||
                        data.scheduledDate == 'tomorrow' ||
                        data.scheduledDate == 'after_tomorrow')
                    ? data.scheduledDate
                    : 'today', // Default to 'today' if the value doesn't match any dropdown item
            onChanged: (val) => cubit.updateSchedule(widget.index, val ?? ''),
            items: _buildScheduleDropdownItems(),
          ),
        );
      },
    );
  }

  Widget _buildImageUploadSection(BuildContext context,
      AddMultipleReportsCubit cubit, dynamic data, bool isDark) {
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
                    onTap: () => cubit.pickImagesFromUI(widget.index, context),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
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
          if (data.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${data.imageUrls.length} صورة مرفقة',
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
              children: data.imageUrls.map<Widget>((url) {
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
                        onTap: () {
                          final current =
                              cubit.state.reports[widget.index].imageUrls ?? [];
                          final updated = List<String>.from(current)
                            ..remove(url);
                          cubit.updateImages(widget.index, updated);
                        },
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

  List<DropdownMenuItem<String>> _buildTypeDropdownItems() {
    return [
      _buildDropdownItem('Electricity', 'كهرباء', 'assets/images/elec.png'),
      _buildDropdownItem('Plumbing', 'سباكة', 'assets/images/plumber.png'),
      _buildDropdownItem('AC', 'تكييف', 'assets/images/air-conditioner.png'),
      _buildDropdownItem('Civil', 'مدني', 'assets/images/civil.png'),
      _buildDropdownItem('Fire', 'حريق', 'assets/images/fire.png'),
    ];
  }

  List<DropdownMenuItem<String>> _buildPriorityDropdownItems() {
    return [
      _buildDropdownItem('Routine', 'روتيني', 'assets/images/routine.png'),
      _buildDropdownItem('Emergency', 'طارئ', 'assets/images/emergency.png'),
    ];
  }

  List<DropdownMenuItem<String>> _buildScheduleDropdownItems() {
    return [
      _buildDropdownItem('today', 'اليوم', 'assets/images/today.png'),
      _buildDropdownItem('tomorrow', 'غدًا', 'assets/images/tomorrow.png'),
      _buildDropdownItem(
          'after_tomorrow', 'بعد الغد', 'assets/images/after.png'),
    ];
  }

  List<DropdownMenuItem<String>> _buildReportSourceDropdownItems() {
    return [
      _buildReportSourceDropdownItem(
          'unifier', 'يونيفاير', Icons.integration_instructions),
      _buildReportSourceDropdownItem(
          'check_list', 'تشيك ليست', Icons.checklist),
      _buildReportSourceDropdownItem('consultant', 'استشاري', Icons.person_2),
    ];
  }

  DropdownMenuItem<String> _buildDropdownItem(
      String value, String label, String iconPath) {
    return DropdownMenuItem(
      value: value,
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Row(
            children: [
              Image.asset(iconPath, width: 14, height: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  DropdownMenuItem<String> _buildReportSourceDropdownItem(
      String value, String label, IconData icon) {
    return DropdownMenuItem(
      value: value,
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
