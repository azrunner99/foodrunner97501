/// Centralized validation service for the NPS system
/// Provides comprehensive validation for all data types and business rules
library;

/// Validation result class
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Create a successful validation result
  factory ValidationResult.success({List<String> warnings = const []}) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// Create a failed validation result
  factory ValidationResult.failure(List<String> errors,
      {List<String> warnings = const []}) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Get formatted error message
  String get errorMessage {
    if (errors.isEmpty) return '';
    return errors.join('\n');
  }

  /// Get formatted warning message
  String get warningMessage {
    if (warnings.isEmpty) return '';
    return warnings.join('\n');
  }

  /// Check if there are any issues (errors or warnings)
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;
}

class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  // Server Name Validation

  /// Validate server name
  ValidationResult validateServerName(String name) {
    final errors = <String>[];
    final warnings = <String>[];

    final trimmedName = name.trim();

    // Required field
    if (trimmedName.isEmpty) {
      errors.add('Server name is required');
      return ValidationResult.failure(errors);
    }

    // Length constraints
    if (trimmedName.length < 2) {
      errors.add('Server name must be at least 2 characters long');
    }

    if (trimmedName.length > 100) {
      errors.add('Server name cannot exceed 100 characters');
    }

    // Character validation - allow letters, spaces, hyphens, apostrophes, and periods
    final namePattern = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!namePattern.hasMatch(trimmedName)) {
      errors.add(
          'Server name can only contain letters, spaces, hyphens, apostrophes, and periods');
    }

    // Business rules
    if (trimmedName.length < 3) {
      warnings.add('Very short names may be unclear to guests');
    }

    if (trimmedName.contains(RegExp(r'\d'))) {
      warnings.add('Server names with numbers may be confusing');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }

  /// Validate hire date
  ValidationResult validateHireDate(DateTime hireDate) {
    final errors = <String>[];
    final warnings = <String>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hireDateOnly = DateTime(hireDate.year, hireDate.month, hireDate.day);

    // Cannot be in the future
    if (hireDateOnly.isAfter(today)) {
      errors.add('Hire date cannot be in the future');
    }

    // Business rule: Cannot be too far in the past
    final tenYearsAgo = today.subtract(const Duration(days: 365 * 10));
    if (hireDateOnly.isBefore(tenYearsAgo)) {
      warnings.add(
          'Hire date is more than 10 years ago - please verify this is correct');
    }

    // Very recent hire
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    if (hireDateOnly.isAfter(threeDaysAgo)) {
      warnings.add(
          'Server was hired very recently - may not have sufficient feedback yet');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }

  // Feedback Validation

  /// Validate feedback date
  ValidationResult validateFeedbackDate(DateTime feedbackDate) {
    final errors = <String>[];
    final warnings = <String>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final feedbackDateOnly =
        DateTime(feedbackDate.year, feedbackDate.month, feedbackDate.day);

    // Cannot be in the future
    if (feedbackDateOnly.isAfter(today)) {
      errors.add('Feedback date cannot be in the future');
    }

    // Business rule: Cannot be too old
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    if (feedbackDateOnly.isBefore(thirtyDaysAgo)) {
      warnings.add('Feedback is older than 30 days - accuracy may be reduced');
    }

    // Very old feedback
    const maxFeedbackAge = 90; // days
    final maxAgeDate = today.subtract(const Duration(days: maxFeedbackAge));
    if (feedbackDateOnly.isBefore(maxAgeDate)) {
      errors.add('Feedback cannot be older than $maxFeedbackAge days');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }

  /// Validate sales amount
  ValidationResult validateSalesAmount(double? salesAmount) {
    final errors = <String>[];
    final warnings = <String>[];

    if (salesAmount == null) {
      return ValidationResult.success(); // Optional field
    }

    // Must be non-negative
    if (salesAmount < 0) {
      errors.add('Sales amount cannot be negative');
    }

    // Business rules
    if (salesAmount == 0) {
      warnings.add('Zero sales amount - was this a comp or special situation?');
    }

    if (salesAmount > 1000) {
      warnings.add('Very high sales amount - please verify this is correct');
    }

    if (salesAmount < 10) {
      warnings.add('Very low sales amount - please verify this is correct');
    }

    // Decimal places
    final decimalPlaces = salesAmount.toString().split('.').length > 1
        ? salesAmount.toString().split('.')[1].length
        : 0;
    if (decimalPlaces > 2) {
      warnings
          .add('Sales amount has more than 2 decimal places - will be rounded');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }

  /// Validate table number
  ValidationResult validateTableNumber(int? tableNumber) {
    final errors = <String>[];
    final warnings = <String>[];

    if (tableNumber == null) {
      return ValidationResult.success(); // Optional field
    }

    // Must be positive
    if (tableNumber <= 0) {
      errors.add('Table number must be positive');
    }

    // Business rules
    if (tableNumber > 999) {
      warnings.add('Very high table number - please verify this is correct');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }

  /// Validate guest count
  ValidationResult validateGuestCount(int? guestCount) {
    final errors = <String>[];
    final warnings = <String>[];

    if (guestCount == null) {
      return ValidationResult.success(); // Optional field
    }

    // Must be positive
    if (guestCount <= 0) {
      errors.add('Guest count must be positive');
    }

    // Business rules
    if (guestCount > 20) {
      warnings.add('Very large party size - please verify this is correct');
    }

    if (guestCount == 1) {
      warnings.add('Single guest - less representative for server evaluation');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }

  /// Validate notes
  ValidationResult validateNotes(String? notes) {
    final errors = <String>[];
    final warnings = <String>[];

    if (notes == null || notes.trim().isEmpty) {
      return ValidationResult.success(); // Optional field
    }

    final trimmedNotes = notes.trim();

    // Length constraint
    if (trimmedNotes.length > 500) {
      errors.add('Notes cannot exceed 500 characters');
    }

    // Content validation
    if (trimmedNotes.length < 3) {
      warnings.add('Very short notes may not provide useful context');
    }

    // Check for inappropriate content (basic profanity filter)
    final inappropriateWords = ['damn', 'hell', 'stupid', 'idiot', 'hate'];
    final lowerNotes = trimmedNotes.toLowerCase();
    for (final word in inappropriateWords) {
      if (lowerNotes.contains(word)) {
        warnings.add('Notes contain potentially inappropriate language');
        break;
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }

  // Comprehensive Validation

  /// Validate complete server data
  ValidationResult validateServerData({
    required String name,
    required DateTime hireDate,
    bool checkDuplicateName = false,
    List<String> existingNames = const [],
  }) {
    final allErrors = <String>[];
    final allWarnings = <String>[];

    // Validate individual fields
    final nameResult = validateServerName(name);
    allErrors.addAll(nameResult.errors);
    allWarnings.addAll(nameResult.warnings);

    final hireDateResult = validateHireDate(hireDate);
    allErrors.addAll(hireDateResult.errors);
    allWarnings.addAll(hireDateResult.warnings);

    // Check for duplicate names
    if (checkDuplicateName && existingNames.isNotEmpty) {
      final trimmedName = name.trim().toLowerCase();
      for (final existingName in existingNames) {
        if (existingName.trim().toLowerCase() == trimmedName) {
          allErrors.add('A server with this name already exists');
          break;
        }
      }
    }

    if (allErrors.isNotEmpty) {
      return ValidationResult.failure(allErrors, warnings: allWarnings);
    }

    return ValidationResult.success(warnings: allWarnings);
  }

  /// Validate complete feedback data
  ValidationResult validateFeedbackData({
    required int serverId,
    required DateTime feedbackDate,
    double? salesAmount,
    int? tableNumber,
    int? guestCount,
    String? notes,
  }) {
    final allErrors = <String>[];
    final allWarnings = <String>[];

    // Validate server ID
    if (serverId <= 0) {
      allErrors.add('Valid server must be selected');
    }

    // Validate individual fields
    final dateResult = validateFeedbackDate(feedbackDate);
    allErrors.addAll(dateResult.errors);
    allWarnings.addAll(dateResult.warnings);

    final salesResult = validateSalesAmount(salesAmount);
    allErrors.addAll(salesResult.errors);
    allWarnings.addAll(salesResult.warnings);

    final tableResult = validateTableNumber(tableNumber);
    allErrors.addAll(tableResult.errors);
    allWarnings.addAll(tableResult.warnings);

    final guestResult = validateGuestCount(guestCount);
    allErrors.addAll(guestResult.errors);
    allWarnings.addAll(guestResult.warnings);

    final notesResult = validateNotes(notes);
    allErrors.addAll(notesResult.errors);
    allWarnings.addAll(notesResult.warnings);

    // Business rule validations
    if (salesAmount != null && guestCount != null) {
      final averagePerGuest = salesAmount / guestCount;
      if (averagePerGuest > 200) {
        allWarnings.add(
            'Very high average per guest (\$${averagePerGuest.toStringAsFixed(2)}) - please verify');
      } else if (averagePerGuest < 10) {
        allWarnings.add(
            'Very low average per guest (\$${averagePerGuest.toStringAsFixed(2)}) - please verify');
      }
    }

    if (allErrors.isNotEmpty) {
      return ValidationResult.failure(allErrors, warnings: allWarnings);
    }

    return ValidationResult.success(warnings: allWarnings);
  }

  // Utility Methods

  /// Clean and format server name
  String cleanServerName(String name) {
    return name
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' '); // Remove extra spaces
  }

  /// Clean and format notes
  String cleanNotes(String notes) {
    return notes
        .trim()
        .replaceAll(
            RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\n+'),
            '\n'); // Replace multiple newlines with single newline
  }

  /// Check if date is a business day (Monday-Friday)
  bool isBusinessDay(DateTime date) {
    return date.weekday >= 1 && date.weekday <= 5;
  }

  /// Check if date is a weekend
  bool isWeekend(DateTime date) {
    return date.weekday == 6 || date.weekday == 7;
  }

  /// Get business day warnings for feedback
  List<String> getBusinessDayWarnings(DateTime feedbackDate) {
    final warnings = <String>[];

    if (isWeekend(feedbackDate)) {
      warnings.add('Weekend feedback may have different service patterns');
    }

    return warnings;
  }
}
