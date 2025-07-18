import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_fonts.dart';
import '../../logic/blocs/schools/schools_bloc.dart';
import '../../data/models/school.dart';
import '../widgets/common/common_widgets.dart';

class SchoolsListScreen extends StatelessWidget {
  const SchoolsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SchoolsBloc()..add(const SchoolsStarted()),
      child: const _SchoolsListScreenContent(),
    );
  }
}

class _SchoolsListScreenContent extends StatelessWidget {
  const _SchoolsListScreenContent();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'قائمة المدارس',
            style: AppFonts.appBarTitle(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<SchoolsBloc>().add(const SchoolsRefreshed()),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E293B),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFF1F5F9),
                    ],
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: BlocBuilder<SchoolsBloc, SchoolsState>(
                  builder: (context, state) {
                    return TextField(
                      onChanged: (value) {
                        context.read<SchoolsBloc>().add(SchoolsSearchChanged(value));
                      },
                      decoration: InputDecoration(
                        hintText: 'البحث في المدارس...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    );
                  },
                ),
              ),

              // Schools List
              Expanded(
                child: BlocBuilder<SchoolsBloc, SchoolsState>(
                  builder: (context, state) {
                    return _buildContent(context, state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SchoolsState state) {
    if (state is SchoolsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل المدارس...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (state is SchoolsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.red.withOpacity(0.7)
                  : Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<SchoolsBloc>().add(const SchoolsRefreshed());
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state is SchoolsLoaded) {
      final filteredSchools = state.filteredSchools;

      if (filteredSchools.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                state.searchQuery.isEmpty
                    ? 'لا توجد مدارس'
                    : 'لا توجد مدارس تطابق البحث',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.withOpacity(0.7),
                ),
              ),
              if (state.searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'جرب البحث بكلمات مختلفة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filteredSchools.length,
        itemBuilder: (context, index) {
          final school = filteredSchools[index];
          return _buildSchoolCard(context, school);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSchoolCard(BuildContext context, School school) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/school-details/${school.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // School Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // School Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    if (school.address != null &&
                        school.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        school.address!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'تاريخ الإضافة: ${_formatDate(school.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
