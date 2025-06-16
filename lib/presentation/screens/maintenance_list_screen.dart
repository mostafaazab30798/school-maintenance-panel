import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorMaintenanceListScreen extends StatelessWidget {
  final String supervisorId;
  const SupervisorMaintenanceListScreen(
      {super.key, required this.supervisorId});

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    final response = await Supabase.instance.client
        .from('maintenance_reports')
        .select()
        .eq('supervisor_id', supervisorId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بلاغات الصيانة')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد بلاغات.'));
          }

          final reports = snapshot.data!;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(report['school_name'] ?? 'بدون اسم'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تاريخ الجدولة: ${report['scheduled_date'] ?? '-'}'),
                      Text('ملاحظات: ${report['description'] ?? '-'}'),
                      Text('صور: ${report['images']?.length ?? 0}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
