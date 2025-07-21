import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Advanced error handling service with resilience patterns
class ErrorHandlingService {
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final Map<String, CircuitBreaker> _circuitBreakers = {};
  final Map<String, RetryPolicy> _retryPolicies = {};
  final List<ErrorHandler> _errorHandlers = [];

  void initialize() {
    _registerDefaultErrorHandlers();
    _logDebug('Error handling service initialized');
  }

  /// Execute operation with error handling and resilience patterns
  Future<T> executeWithResilience<T>(
    String operationName,
    Future<T> Function() operation, {
    RetryPolicy? retryPolicy,
    Duration? timeout,
    T? fallbackValue,
    Future<T> Function()? fallbackOperation,
  }) async {
    final circuitBreaker = _getCircuitBreaker(operationName);
    final policy = retryPolicy ?? _getRetryPolicy(operationName);

    return await circuitBreaker.execute(() async {
      return await _executeWithRetry(
        operationName,
        operation,
        policy,
        timeout: timeout,
        fallbackValue: fallbackValue,
        fallbackOperation: fallbackOperation,
      );
    });
  }

  /// Register custom error handler
  void registerErrorHandler(ErrorHandler handler) {
    _errorHandlers.add(handler);
    _logDebug('Registered error handler: ${handler.runtimeType}');
  }

  /// Handle error with registered handlers
  Future<void> handleError(
    String context,
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? metadata,
  }) async {
    final errorInfo = ErrorInfo(
      context: context,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    for (final handler in _errorHandlers) {
      try {
        if (handler.canHandle(errorInfo)) {
          await handler.handle(errorInfo);
        }
      } catch (handlerError) {
        _logError(
            'Error in error handler ${handler.runtimeType}: $handlerError');
      }
    }
  }

  /// Configure retry policy for operation
  void configureRetryPolicy(String operationName, RetryPolicy policy) {
    _retryPolicies[operationName] = policy;
    _logDebug('Configured retry policy for $operationName');
  }

  /// Configure circuit breaker for operation
  void configureCircuitBreaker(
    String operationName, {
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 60),
    Duration resetTimeout = const Duration(minutes: 5),
  }) {
    _circuitBreakers[operationName] = CircuitBreaker(
      operationName,
      failureThreshold: failureThreshold,
      timeout: timeout,
      resetTimeout: resetTimeout,
    );
    _logDebug('Configured circuit breaker for $operationName');
  }

  /// Get circuit breaker status
  Map<String, CircuitBreakerStatus> getCircuitBreakerStatus() {
    return _circuitBreakers.map(
      (key, breaker) => MapEntry(key, breaker.status),
    );
  }

  Future<T> _executeWithRetry<T>(
    String operationName,
    Future<T> Function() operation,
    RetryPolicy policy, {
    Duration? timeout,
    T? fallbackValue,
    Future<T> Function()? fallbackOperation,
  }) async {
    int attempt = 0;
    Duration delay = policy.initialDelay;

    while (attempt < policy.maxAttempts) {
      try {
        attempt++;

        Future<T> operationFuture = operation();
        if (timeout != null) {
          operationFuture = operationFuture.timeout(timeout);
        }

        final result = await operationFuture;

        if (attempt > 1) {
          _logInfo('Operation $operationName succeeded on attempt $attempt');
        }

        return result;
      } catch (error, stackTrace) {
        final shouldRetry = policy.shouldRetry(error, attempt);

        // 🚀 ENHANCED: Use detailed error logging
        _logDetailedError('$operationName (attempt $attempt)', error, stackTrace);
        
        await handleError(
          'Operation: $operationName (attempt $attempt)',
          error,
          stackTrace,
          metadata: {
            'operationName': operationName,
            'attempt': attempt,
            'maxAttempts': policy.maxAttempts,
            'willRetry': shouldRetry && attempt < policy.maxAttempts,
          },
        );

        if (!shouldRetry || attempt >= policy.maxAttempts) {
          _logError('Operation $operationName failed after $attempt attempts');

          // Try fallback operation
          if (fallbackOperation != null) {
            try {
              _logInfo('Executing fallback operation for $operationName');
              return await fallbackOperation();
            } catch (fallbackError) {
              _logError(
                  'Fallback operation failed for $operationName: $fallbackError');
            }
          }

          // Return fallback value if available
          if (fallbackValue != null) {
            _logInfo('Returning fallback value for $operationName');
            return fallbackValue;
          }

          rethrow;
        }

        if (attempt < policy.maxAttempts) {
          _logWarning(
              'Retrying operation $operationName in ${delay.inMilliseconds}ms (attempt $attempt)');
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: min(
              (delay.inMilliseconds * policy.backoffMultiplier).round(),
              policy.maxDelay.inMilliseconds,
            ),
          );
        }
      }
    }

    throw Exception(
        'Operation $operationName failed after ${policy.maxAttempts} attempts');
  }

  CircuitBreaker _getCircuitBreaker(String operationName) {
    return _circuitBreakers.putIfAbsent(
      operationName,
      () => CircuitBreaker(operationName),
    );
  }

  RetryPolicy _getRetryPolicy(String operationName) {
    return _retryPolicies[operationName] ?? RetryPolicy.defaultPolicy();
  }

  void _registerDefaultErrorHandlers() {
    registerErrorHandler(LoggingErrorHandler());
    registerErrorHandler(PerformanceTrackingErrorHandler());
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('ErrorHandling: $message');
    }
  }

  void _logInfo(String message) {
    if (kDebugMode) {
      debugPrint('ErrorHandling INFO: $message');
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
      debugPrint('ErrorHandling WARNING: $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      debugPrint('ErrorHandling ERROR: $message');
    }
  }

  /// Enhanced error logging with detailed information
  void _logDetailedError(String operationName, dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('🔍 DETAILED ERROR for $operationName:');
      debugPrint('   Error type: ${error.runtimeType}');
      debugPrint('   Error message: $error');
      debugPrint('   Error toString: ${error.toString()}');
      
      // Check for specific error types
      if (error.toString().contains('PostgrestException')) {
        debugPrint('   🚨 This is a PostgrestException (database error)');
      } else if (error.toString().contains('AuthException')) {
        debugPrint('   🚨 This is an AuthException (authentication error)');
      } else if (error.toString().contains('TimeoutException')) {
        debugPrint('   🚨 This is a TimeoutException (timeout error)');
      } else if (error.toString().contains('SocketException')) {
        debugPrint('   🚨 This is a SocketException (network error)');
      }
      
      if (stackTrace != null) {
        debugPrint('   Stack trace: $stackTrace');
      }
      debugPrint('🔍 END DETAILED ERROR');
    }
  }
}

/// Circuit breaker implementation
class CircuitBreaker {
  final String operationName;
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _nextAttemptTime;

  CircuitBreaker(
    this.operationName, {
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 60),
    this.resetTimeout = const Duration(minutes: 5),
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_nextAttemptTime != null &&
          DateTime.now().isBefore(_nextAttemptTime!)) {
        throw CircuitBreakerOpenException(operationName);
      } else {
        _state = CircuitBreakerState.halfOpen;
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    _lastFailureTime = null;
    _nextAttemptTime = null;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      _nextAttemptTime = DateTime.now().add(resetTimeout);
    }
  }

  CircuitBreakerStatus get status => CircuitBreakerStatus(
        operationName: operationName,
        state: _state,
        failureCount: _failureCount,
        lastFailureTime: _lastFailureTime,
        nextAttemptTime: _nextAttemptTime,
      );
}

/// Retry policy configuration
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool Function(dynamic error, int attempt) shouldRetry;

  RetryPolicy({
    required this.maxAttempts,
    required this.initialDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
    required this.shouldRetry,
  });

  factory RetryPolicy.defaultPolicy() {
    return RetryPolicy(
      maxAttempts: 3,
      initialDelay: const Duration(milliseconds: 500),
      maxDelay: const Duration(seconds: 10),
      backoffMultiplier: 2.0,
      shouldRetry: (error, attempt) => true,
    );
  }

  factory RetryPolicy.networkPolicy() {
    return RetryPolicy(
      maxAttempts: 5,
      initialDelay: const Duration(seconds: 1),
      maxDelay: const Duration(seconds: 30),
      backoffMultiplier: 2.0,
      shouldRetry: (error, attempt) {
        return error is TimeoutException ||
            error.toString().contains('network') ||
            error.toString().contains('connection');
      },
    );
  }
}

/// Error handler interface
abstract class ErrorHandler {
  bool canHandle(ErrorInfo errorInfo);
  Future<void> handle(ErrorInfo errorInfo);
}

/// Logging error handler
class LoggingErrorHandler implements ErrorHandler {
  @override
  bool canHandle(ErrorInfo errorInfo) => true;

  @override
  Future<void> handle(ErrorInfo errorInfo) async {
    if (kDebugMode) {
      debugPrint('ERROR [${errorInfo.context}]: ${errorInfo.error}');
      if (errorInfo.stackTrace != null) {
        debugPrint('Stack trace: ${errorInfo.stackTrace}');
      }
    }
  }
}

/// Performance tracking error handler
class PerformanceTrackingErrorHandler implements ErrorHandler {
  @override
  bool canHandle(ErrorInfo errorInfo) => true;

  @override
  Future<void> handle(ErrorInfo errorInfo) async {
    // Record error in performance monitoring
    // This integrates with our PerformanceMonitoringService
  }
}

/// Error information container
class ErrorInfo {
  final String context;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ErrorInfo({
    required this.context,
    required this.error,
    this.stackTrace,
    required this.timestamp,
    this.metadata,
  });
}

/// Circuit breaker states
enum CircuitBreakerState { closed, open, halfOpen }

/// Circuit breaker status
class CircuitBreakerStatus {
  final String operationName;
  final CircuitBreakerState state;
  final int failureCount;
  final DateTime? lastFailureTime;
  final DateTime? nextAttemptTime;

  CircuitBreakerStatus({
    required this.operationName,
    required this.state,
    required this.failureCount,
    this.lastFailureTime,
    this.nextAttemptTime,
  });

  Map<String, dynamic> toJson() => {
        'operationName': operationName,
        'state': state.toString(),
        'failureCount': failureCount,
        'lastFailureTime': lastFailureTime?.toIso8601String(),
        'nextAttemptTime': nextAttemptTime?.toIso8601String(),
      };
}

/// Circuit breaker exception
class CircuitBreakerOpenException implements Exception {
  final String operationName;

  CircuitBreakerOpenException(this.operationName);

  @override
  String toString() => 'Circuit breaker is open for operation: $operationName';
}
