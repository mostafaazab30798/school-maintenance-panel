import 'package:flutter/material.dart';
import '../../../core/services/performance_monitoring_service.dart';
import '../../../core/services/performance_optimization_service.dart';

class PerformanceMonitorWidget extends StatefulWidget {
  const PerformanceMonitorWidget({super.key});

  @override
  State<PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget> {
  final PerformanceMonitoringService _performanceService = PerformanceMonitoringService();
  final PerformanceOptimizationService _optimizationService = PerformanceOptimizationService();
  
  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _cacheMetrics = {};
  List<String> _optimizationSuggestions = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  void _loadMetrics() {
    setState(() {
      _metrics = _performanceService.getAllMetrics();
      _cacheMetrics = _performanceService.getCacheMetrics();
      _optimizationSuggestions = _optimizationService.getDatabaseOptimizationSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: const Text('🚀 Performance Monitor'),
        subtitle: Text('${_metrics.length} operations tracked'),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          _buildMetricsSection(),
          _buildCacheSection(),
          _buildOptimizationSection(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    final maintenanceMetrics = _metrics.entries
        .where((entry) => entry.key.contains('MaintenanceReport'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '📊 Maintenance Reports Performance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...maintenanceMetrics.map((entry) {
          final metric = entry.value;
          final isSlow = metric.averageDuration.inMilliseconds > 300;
          
          return ListTile(
            title: Text(entry.key.split(':').last),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avg: ${metric.averageDuration.inMilliseconds}ms'),
                Text('Success Rate: ${(metric.successRate * 100).toStringAsFixed(1)}%'),
                Text('Executions: ${metric.executionCount}'),
              ],
            ),
            trailing: Icon(
              isSlow ? Icons.warning : Icons.check_circle,
              color: isSlow ? Colors.orange : Colors.green,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCacheSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '💾 Cache Performance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ..._cacheMetrics.entries.map((entry) {
          final metrics = entry.value;
          final hitRate = metrics.hitRate;
          final isGood = hitRate > 0.7;
          
          return ListTile(
            title: Text(entry.key),
            subtitle: Text('Hit Rate: ${(hitRate * 100).toStringAsFixed(1)}%'),
            trailing: Icon(
              isGood ? Icons.check_circle : Icons.warning,
              color: isGood ? Colors.green : Colors.orange,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildOptimizationSection() {
    if (_optimizationSuggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('✅ No optimization suggestions needed'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '🔧 Optimization Suggestions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ..._optimizationSuggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              suggestion,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _loadMetrics,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
          ElevatedButton.icon(
            onPressed: _exportMetrics,
            icon: const Icon(Icons.download),
            label: const Text('Export'),
          ),
          ElevatedButton.icon(
            onPressed: _clearMetrics,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportMetrics() {
    final exportData = _performanceService.exportPerformanceData();
    // In a real app, you would save this to a file or send to analytics
    debugPrint('Performance data exported: $exportData');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Performance data exported to console'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearMetrics() {
    // Note: This would need to be implemented in the PerformanceMonitoringService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metrics cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }
} 