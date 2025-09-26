import 'package:flutter/material.dart';
import '../utils/log.dart';

/// Error Handling Service for User-Friendly Error Management
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  /// Handle database errors with user-friendly messages
  static String handleDatabaseError(dynamic error) {
    d('[ErrorHandlingService] Database error: $error');
    
    if (error.toString().contains('no such table')) {
      return 'Database structure issue detected. Please restart the app to fix this.';
    } else if (error.toString().contains('no such column')) {
      return 'Database schema mismatch detected. Please restart the app to update the database.';
    } else if (error.toString().contains('UNIQUE constraint failed')) {
      return 'This data already exists. The system will update the existing record instead.';
    } else if (error.toString().contains('database is locked')) {
      return 'Database is temporarily busy. Please try again in a moment.';
    } else {
      return 'A database error occurred. Please try again or restart the app if the problem persists.';
    }
  }

  /// Get user-friendly error message based on error type
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('database') || errorString.contains('sqlite')) {
      return handleDatabaseError(error);
    } else if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Network error occurred. Please check your internet connection and try again.';
    } else if (errorString.contains('validation') || errorString.contains('required')) {
      return 'Please check your input data and try again.';
    } else {
      return 'An unexpected error occurred. Please try again or restart the app if the problem persists.';
    }
  }

  /// Show error snackbar with user-friendly message
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}