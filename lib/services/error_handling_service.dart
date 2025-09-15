import 'package:flutter/material.dart';

/// Comprehensive error handling service for the NPS system
/// Provides centralized error management, logging, and user-friendly error presentation

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

enum ErrorCategory {
  database,
  network,
  validation,
  business,
  system,
  user,
}

/// Application error class with comprehensive error information
class AppError {
  final String code;
  final String message;
  final String? technicalDetails;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final DateTime timestamp;
  final String? userAction;
  final Exception? originalException;
  final StackTrace? stackTrace;

  AppError({
    required this.code,
    required this.message,
    this.technicalDetails,
    this.severity = ErrorSeverity.error,
    this.category = ErrorCategory.system,
    this.userAction,
    this.originalException,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  /// Create AppError with current timestamp
  factory AppError.create({
    required String code,
    required String message,
    String? technicalDetails,
    ErrorSeverity severity = ErrorSeverity.error,
    ErrorCategory category = ErrorCategory.system,
    String? userAction,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: code,
      message: message,
      technicalDetails: technicalDetails,
      severity: severity,
      category: category,
      userAction: userAction,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (severity) {
      case ErrorSeverity.info:
        return message;
      case ErrorSeverity.warning:
        return message;
      case ErrorSeverity.error:
        return '$message${userAction != null ? "\n\n$userAction" : ""}';
      case ErrorSeverity.critical:
        return '$message\n\nPlease contact support if this problem persists.';
    }
  }

  /// Get error color for UI display
  Color get color {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  /// Get error icon for UI display
  IconData get icon {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info;
      case ErrorSeverity.warning:
        return Icons.warning;
      case ErrorSeverity.error:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.error_outline;
    }
  }

  @override
  String toString() {
    return 'AppError{code: $code, message: $message, severity: $severity, category: $category, timestamp: $timestamp}';
  }
}

/// Centralized error handling service
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final List<AppError> _errorLog = [];
  final int _maxLogSize = 100;

  /// Get all logged errors
  List<AppError> get errorLog => List.unmodifiable(_errorLog);

  /// Log an error
  void logError(AppError error) {
    _errorLog.insert(0, error);
    
    // Keep log size manageable
    if (_errorLog.length > _maxLogSize) {
      _errorLog.removeRange(_maxLogSize, _errorLog.length);
    }

    // Print to console for debugging
    debugPrint('[${error.severity.name.toUpperCase()}] ${error.code}: ${error.message}');
    if (error.technicalDetails != null) {
      debugPrint('Technical Details: ${error.technicalDetails}');
    }
    if (error.originalException != null) {
      debugPrint('Original Exception: ${error.originalException}');
    }
  }

  /// Clear error log
  void clearLog() {
    _errorLog.clear();
  }

  /// Get errors by category
  List<AppError> getErrorsByCategory(ErrorCategory category) {
    return _errorLog.where((error) => error.category == category).toList();
  }

  /// Get errors by severity
  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorLog.where((error) => error.severity == severity).toList();
  }

  /// Database Error Handlers

  /// Handle database connection errors
  AppError handleDatabaseConnectionError(Exception e) {
    final error = AppError.create(
      code: 'DB_CONNECTION_FAILED',
      message: 'Unable to connect to the database',
      technicalDetails: e.toString(),
      severity: ErrorSeverity.critical,
      category: ErrorCategory.database,
      userAction: 'Please restart the application. If the problem persists, contact support.',
      originalException: e,
    );
    logError(error);
    return error;
  }

  /// Handle database query errors
  AppError handleDatabaseQueryError(Exception e, String operation) {
    final error = AppError.create(
      code: 'DB_QUERY_FAILED',
      message: 'Database operation failed: $operation',
      technicalDetails: e.toString(),
      severity: ErrorSeverity.error,
      category: ErrorCategory.database,
      userAction: 'Please try again. If the problem continues, restart the application.',
      originalException: e,
    );
    logError(error);
    return error;
  }

  /// Handle database constraint violations
  AppError handleDatabaseConstraintError(Exception e, String details) {
    final error = AppError.create(
      code: 'DB_CONSTRAINT_VIOLATION',
      message: 'Data integrity constraint violated',
      technicalDetails: '$details: ${e.toString()}',
      severity: ErrorSeverity.error,
      category: ErrorCategory.database,
      userAction: 'Please check your data and try again.',
      originalException: e,
    );
    logError(error);
    return error;
  }

  /// Validation Error Handlers

  /// Handle validation failures
  AppError handleValidationError(List<String> validationErrors) {
    final error = AppError.create(
      code: 'VALIDATION_FAILED',
      message: 'Please correct the following issues:\n${validationErrors.join('\n')}',
      technicalDetails: 'Validation errors: ${validationErrors.join(', ')}',
      severity: ErrorSeverity.warning,
      category: ErrorCategory.validation,
      userAction: 'Please review and correct the highlighted fields.',
    );
    logError(error);
    return error;
  }

  /// Handle business rule violations
  AppError handleBusinessRuleError(String rule, String details) {
    final error = AppError.create(
      code: 'BUSINESS_RULE_VIOLATION',
      message: 'Business rule violation: $rule',
      technicalDetails: details,
      severity: ErrorSeverity.error,
      category: ErrorCategory.business,
      userAction: 'Please review the business requirements and try again.',
    );
    logError(error);
    return error;
  }

  /// Server Management Error Handlers

  /// Handle server not found errors
  AppError handleServerNotFoundError(String serverId) {
    final error = AppError.create(
      code: 'SERVER_NOT_FOUND',
      message: 'Server not found',
      technicalDetails: 'Server ID: $serverId',
      severity: ErrorSeverity.error,
      category: ErrorCategory.business,
      userAction: 'Please refresh the server list and try again.',
    );
    logError(error);
    return error;
  }

  /// Handle server duplicate name errors
  AppError handleServerDuplicateNameError(String name) {
    final error = AppError.create(
      code: 'SERVER_DUPLICATE_NAME',
      message: 'A server with the name "$name" already exists',
      technicalDetails: 'Attempted to create duplicate server name: $name',
      severity: ErrorSeverity.error,
      category: ErrorCategory.business,
      userAction: 'Please choose a different name for the server.',
    );
    logError(error);
    return error;
  }

  /// Handle server with feedback deletion attempts
  AppError handleServerWithFeedbackDeletionError(String serverName) {
    final error = AppError.create(
      code: 'SERVER_HAS_FEEDBACK',
      message: 'Cannot delete server "$serverName" because it has feedback records',
      technicalDetails: 'Attempted to delete server with existing feedback: $serverName',
      severity: ErrorSeverity.error,
      category: ErrorCategory.business,
      userAction: 'Archive the server instead of deleting it to preserve feedback history.',
    );
    logError(error);
    return error;
  }

  /// Feedback Error Handlers

  /// Handle feedback for inactive server errors
  AppError handleInactiveServerFeedbackError(String serverName) {
    final error = AppError.create(
      code: 'INACTIVE_SERVER_FEEDBACK',
      message: 'Cannot submit feedback for inactive server "$serverName"',
      technicalDetails: 'Attempted to submit feedback for inactive server: $serverName',
      severity: ErrorSeverity.error,
      category: ErrorCategory.business,
      userAction: 'Please select an active server or reactivate this server first.',
    );
    logError(error);
    return error;
  }

  /// Handle feedback date errors
  AppError handleFeedbackDateError(DateTime attemptedDate) {
    final error = AppError.create(
      code: 'INVALID_FEEDBACK_DATE',
      message: 'Invalid feedback date: ${attemptedDate.toString().split(' ')[0]}',
      technicalDetails: 'Feedback date cannot be in the future or too far in the past',
      severity: ErrorSeverity.error,
      category: ErrorCategory.validation,
      userAction: 'Please select a valid date within the allowed range.',
    );
    logError(error);
    return error;
  }

  /// System Error Handlers

  /// Handle unexpected system errors
  AppError handleUnexpectedError(Exception e, String context) {
    final error = AppError.create(
      code: 'UNEXPECTED_ERROR',
      message: 'An unexpected error occurred',
      technicalDetails: 'Context: $context, Error: ${e.toString()}',
      severity: ErrorSeverity.critical,
      category: ErrorCategory.system,
      userAction: 'Please restart the application and try again.',
      originalException: e,
    );
    logError(error);
    return error;
  }

  /// Handle file system errors
  AppError handleFileSystemError(Exception e, String operation) {
    final error = AppError.create(
      code: 'FILE_SYSTEM_ERROR',
      message: 'File system operation failed: $operation',
      technicalDetails: e.toString(),
      severity: ErrorSeverity.error,
      category: ErrorCategory.system,
      userAction: 'Please check file permissions and available storage space.',
      originalException: e,
    );
    logError(error);
    return error;
  }

  /// User Interface Error Handlers

  /// Handle UI navigation errors
  AppError handleNavigationError(String route, Exception e) {
    final error = AppError.create(
      code: 'NAVIGATION_ERROR',
      message: 'Failed to navigate to $route',
      technicalDetails: e.toString(),
      severity: ErrorSeverity.error,
      category: ErrorCategory.user,
      userAction: 'Please try navigating again or restart the application.',
      originalException: e,
    );
    logError(error);
    return error;
  }

  /// Handle form submission errors
  AppError handleFormSubmissionError(String formName, Exception e) {
    final error = AppError.create(
      code: 'FORM_SUBMISSION_ERROR',
      message: 'Failed to submit $formName',
      technicalDetails: e.toString(),
      severity: ErrorSeverity.error,
      category: ErrorCategory.user,
      userAction: 'Please check your input and try again.',
      originalException: e,
    );
    logError(error);
    return error;
  }

  /// Recovery and Retry Logic

  /// Check if error is recoverable
  bool isRecoverable(AppError error) {
    switch (error.category) {
      case ErrorCategory.validation:
      case ErrorCategory.user:
        return true;
      case ErrorCategory.network:
      case ErrorCategory.database:
        return error.severity != ErrorSeverity.critical;
      case ErrorCategory.business:
        return true;
      case ErrorCategory.system:
        return error.severity == ErrorSeverity.error;
    }
  }

  /// Get retry suggestion for error
  String? getRetrySuggestion(AppError error) {
    if (!isRecoverable(error)) {
      return null;
    }

    switch (error.category) {
      case ErrorCategory.network:
        return 'Check your internet connection and try again';
      case ErrorCategory.database:
        return 'Please wait a moment and try again';
      case ErrorCategory.validation:
        return 'Please correct the errors and try again';
      case ErrorCategory.business:
        return 'Please review the requirements and try again';
      case ErrorCategory.user:
        return 'Please try again';
      case ErrorCategory.system:
        return 'Please restart the application and try again';
    }
  }

  /// Show error to user with appropriate UI
  void showErrorToUser(BuildContext context, AppError error) {
    final retrySuggestion = getRetrySuggestion(error);

    if (error.severity == ErrorSeverity.critical) {
      // Show dialog for critical errors
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(error.icon, color: error.color),
              const SizedBox(width: 8),
              const Text('Critical Error'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.userMessage),
              if (retrySuggestion != null) ...[
                const SizedBox(height: 16),
                Text(
                  retrySuggestion,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show snack bar for other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(error.icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(error.userMessage)),
            ],
          ),
          backgroundColor: error.color,
          duration: Duration(
            seconds: error.severity == ErrorSeverity.warning ? 4 : 6,
          ),
          action: retrySuggestion != null
              ? SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Error Details'),
                        content: Text(retrySuggestion),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }
}