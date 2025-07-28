import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../logic/blocs/fci_assessments/fci_assessments_bloc.dart';
import '../../data/models/fci_assessment.dart';
import '../widgets/common/shared_app_bar.dart';
import '../widgets/common/error_widget.dart';
import '../../core/services/admin_service.dart';
import '../../data/repositories/fci_assessment_repository.dart';

class FciAssessmentsScreen extends StatelessWidget {
  final String? status;
  final String? view;

  const FciAssessmentsScreen({
    super.key,
    this.status,
    this.view,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (context) => FciAssessmentsBloc(
          context.read<FciAssessmentRepository>(),
          context.read<AdminService>(),
        )..add(FciAssessmentsStarted(status: status, view: view)),
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          appBar: const SharedAppBar(
            title: 'تقييمات FCI',
          ),
          body: BlocBuilder<FciAssessmentsBloc, FciAssessmentsState>(
            builder: (context, state) {
              if (state is FciAssessmentsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B5CF6),
                  ),
                );
              }

              if (state is FciAssessmentsFailure) {
                return AppErrorWidget(
                  message: state.message,
                  onRetry: () {
                    context.read<FciAssessmentsBloc>().add(
                          FciAssessmentsRefresh(status: status, view: view),
                        );
                  },
                );
              }

              if (state is FciAssessmentsLoaded) {
                return _buildContent(context, state);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FciAssessmentsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FciAssessmentsBloc>().add(
              FciAssessmentsRefresh(status: status, view: view),
            );
      },
      child: CustomScrollView(
        slivers: [
          // Header with filters
          SliverToBoxAdapter(
            child: _buildHeader(context, state),
          ),
          
          // Content based on view type
          if (state.view == 'schools')
            _buildSchoolsList(context, state)
          else
            _buildAssessmentsList(context, state),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FciAssessmentsLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF1E293B).withOpacity(0.8),
                  const Color(0xFF334155).withOpacity(0.6),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  const Color(0xFFF8FAFC).withOpacity(0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155).withOpacity(0.5)
              : const Color(0xFFE2E8F0).withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF64748B).withOpacity(0.06),
            offset: const Offset(0, 8),
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.15),
                      const Color(0xFF7C3AED).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.assessment_outlined,
                  size: 24,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقييمات FCI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.view == 'schools'
                          ? '${state.schoolsWithAssessments.length} مدرسة'
                          : '${state.assessments.length} تقييم',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Filter badges
          if (state.status != null || state.view != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (state.status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'الحالة: ${state.status == 'submitted' ? 'مكتملة' : 'مسودة'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                if (state.view != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'عرض المدارس',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessmentsList(BuildContext context, FciAssessmentsLoaded state) {
    if (state.assessments.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 64,
                color: Color(0xFF8B5CF6),
              ),
              SizedBox(height: 16),
              Text(
                'لا توجد تقييمات FCI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final assessment = state.assessments[index];
          return _buildAssessmentCard(context, assessment);
        },
        childCount: state.assessments.length,
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context, FciAssessment assessment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155).withOpacity(0.5)
              : const Color(0xFFE2E8F0).withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : const Color(0xFF64748B).withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: assessment.status == 'submitted'
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFF26A69A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            assessment.status == 'submitted'
                ? Icons.check_circle_outline
                : Icons.edit_outlined,
            color: assessment.status == 'submitted'
                ? const Color(0xFF10B981)
                : const Color(0xFF26A69A),
            size: 24,
          ),
        ),
        title: Text(
          assessment.schoolName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF334155),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'الحالة: ${assessment.status == 'submitted' ? 'مكتملة' : 'مسودة'}',
              style: TextStyle(
                fontSize: 14,
                color: assessment.status == 'submitted'
                    ? const Color(0xFF10B981)
                    : const Color(0xFF26A69A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'المشرف: ${assessment.supervisorName.isNotEmpty ? assessment.supervisorName : 'غير محدد'}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'تاريخ الإنشاء: ${_formatDate(assessment.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : const Color(0xFF64748B),
        ),
        onTap: () {
          // Ensure we're passing a proper FciAssessment object
          if (assessment is FciAssessment) {
            context.push('/fci-assessment-details', extra: assessment);
          } else {
            // If somehow we have a Map, convert it first
            print('⚠️ Warning: Assessment is not FciAssessment type, converting...');
            try {
              final convertedAssessment = FciAssessment.fromJson(assessment.toJson());
              context.push('/fci-assessment-details', extra: convertedAssessment);
            } catch (e) {
              print('❌ Error converting assessment: $e');
              // Show error dialog or snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('خطأ في تحميل بيانات التقييم'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildSchoolsList(BuildContext context, FciAssessmentsLoaded state) {
    if (state.schoolsWithAssessments.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Color(0xFF8B5CF6),
              ),
              SizedBox(height: 16),
              Text(
                'لا توجد مدارس مع تقييمات FCI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final school = state.schoolsWithAssessments[index];
          return _buildSchoolCard(context, school);
        },
        childCount: state.schoolsWithAssessments.length,
      ),
    );
  }

  Widget _buildSchoolCard(BuildContext context, Map<String, dynamic> school) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155).withOpacity(0.5)
              : const Color(0xFFE2E8F0).withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : const Color(0xFF64748B).withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: Color(0xFF3B82F6),
            size: 24,
          ),
        ),
        title: Text(
          school['school_name'] ?? 'مدرسة غير معروفة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF334155),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'عدد التقييمات: ${school['assessment_count'] ?? 0}',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'المشرف: ${school['supervisor_name']?.isNotEmpty == true ? school['supervisor_name'] : 'غير محدد'}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'آخر تقييم: ${_formatDate(DateTime.parse(school['latest_assessment_date'] ?? DateTime.now().toIso8601String()))}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : const Color(0xFF64748B),
        ),
        onTap: () {
          context.push('/school-details/${school['school_id']}');
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 