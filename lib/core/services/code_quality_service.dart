import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Code quality analysis service for automated quality metrics
class CodeQualityService {
  static final CodeQualityService _instance = CodeQualityService._internal();
  factory CodeQualityService() => _instance;
  CodeQualityService._internal();

  final Map<String, QualityMetrics> _qualityMetrics = {};
  final List<QualityRule> _qualityRules = [];

  void initialize() {
    _registerDefaultQualityRules();
    _logDebug('Code quality service initialized');
  }

  /// Analyze code quality for a specific component
  Future<QualityReport> analyzeComponent(
      String componentName, String filePath) async {
    try {
      final metrics = QualityMetrics(
        componentName: componentName,
        filePath: filePath,
        linesOfCode: 100, // Simplified for demo
        cyclomaticComplexity: 8,
        maintainabilityIndex: 75.0,
        codeSmells: [],
        duplicatedLines: 0,
        testCoverage: 0.85,
        dependencies: [],
        timestamp: DateTime.now(),
      );

      _qualityMetrics[componentName] = metrics;

      final violations = _checkQualityRules(metrics);

      return QualityReport(
        componentName: componentName,
        metrics: metrics,
        violations: violations,
        overallScore: _calculateOverallScore(metrics, violations),
        recommendations: _generateRecommendations(metrics, violations),
      );
    } catch (error) {
      _logError('Error analyzing component $componentName: $error');
      rethrow;
    }
  }

  /// Get quality metrics for component
  QualityMetrics? getComponentMetrics(String componentName) {
    return _qualityMetrics[componentName];
  }

  /// Export quality data
  Map<String, dynamic> exportQualityData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'metrics':
          _qualityMetrics.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  List<QualityViolation> _checkQualityRules(QualityMetrics metrics) {
    final violations = <QualityViolation>[];

    for (final rule in _qualityRules) {
      final violation = rule.check(metrics);
      if (violation != null) {
        violations.add(violation);
      }
    }

    return violations;
  }

  double _calculateOverallScore(
      QualityMetrics metrics, List<QualityViolation> violations) {
    double score = 100.0;

    for (final violation in violations) {
      switch (violation.severity) {
        case ViolationSeverity.critical:
          score -= 20;
          break;
        case ViolationSeverity.major:
          score -= 10;
          break;
        case ViolationSeverity.minor:
          score -= 5;
          break;
      }
    }

    return score.clamp(0.0, 100.0);
  }

  List<String> _generateRecommendations(
      QualityMetrics metrics, List<QualityViolation> violations) {
    final recommendations = <String>[];

    if (metrics.cyclomaticComplexity > 15) {
      recommendations.add('Consider breaking down complex methods');
    }

    if (violations.isNotEmpty) {
      recommendations.add('Fix quality rule violations');
    }

    return recommendations;
  }

  void _registerDefaultQualityRules() {
    _qualityRules.add(ComplexityRule());
    _qualityRules.add(MaintainabilityRule());
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('CodeQuality: $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      debugPrint('CodeQuality ERROR: $message');
    }
  }
}

class QualityMetrics {
  final String componentName;
  final String filePath;
  final int linesOfCode;
  final int cyclomaticComplexity;
  final double maintainabilityIndex;
  final List<CodeSmell> codeSmells;
  final int duplicatedLines;
  final double testCoverage;
  final List<String> dependencies;
  final DateTime timestamp;

  QualityMetrics({
    required this.componentName,
    required this.filePath,
    required this.linesOfCode,
    required this.cyclomaticComplexity,
    required this.maintainabilityIndex,
    required this.codeSmells,
    required this.duplicatedLines,
    required this.testCoverage,
    required this.dependencies,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'componentName': componentName,
        'linesOfCode': linesOfCode,
        'cyclomaticComplexity': cyclomaticComplexity,
        'maintainabilityIndex': maintainabilityIndex,
        'testCoverage': testCoverage,
      };
}

class QualityReport {
  final String componentName;
  final QualityMetrics metrics;
  final List<QualityViolation> violations;
  final double overallScore;
  final List<String> recommendations;

  QualityReport({
    required this.componentName,
    required this.metrics,
    required this.violations,
    required this.overallScore,
    required this.recommendations,
  });
}

class CodeSmell {
  final String type;
  final String description;

  CodeSmell({required this.type, required this.description});
}

abstract class QualityRule {
  String get name;
  QualityViolation? check(QualityMetrics metrics);
}

class ComplexityRule extends QualityRule {
  @override
  String get name => 'Complexity Rule';

  @override
  QualityViolation? check(QualityMetrics metrics) {
    if (metrics.cyclomaticComplexity > 20) {
      return QualityViolation(
        rule: name,
        description: 'Complexity too high: ${metrics.cyclomaticComplexity}',
        severity: ViolationSeverity.critical,
        component: metrics.componentName,
      );
    }
    return null;
  }
}

class MaintainabilityRule extends QualityRule {
  @override
  String get name => 'Maintainability Rule';

  @override
  QualityViolation? check(QualityMetrics metrics) {
    if (metrics.maintainabilityIndex < 40) {
      return QualityViolation(
        rule: name,
        description: 'Maintainability too low: ${metrics.maintainabilityIndex}',
        severity: ViolationSeverity.major,
        component: metrics.componentName,
      );
    }
    return null;
  }
}

class QualityViolation {
  final String rule;
  final String description;
  final ViolationSeverity severity;
  final String component;

  QualityViolation({
    required this.rule,
    required this.description,
    required this.severity,
    required this.component,
  });
}

enum ViolationSeverity { minor, major, critical }
