/// Data models for the Server NPS system
///
/// These models represent the structure of data used in the NPS tracking system,
/// including servers, feedback, and monthly reports.
library;
import '../core/types.dart';

/// Represents a server in the NPS system
class NPSServer {
  final ServerId id; // Standardized to non-nullable String
  final String name;
  final String? originalId; // Original server ID from main app
  final DateTime hireDate;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NPSServer({
    required this.id,
    required this.name,
    this.originalId,
    required this.hireDate,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Create an NPSServer from a database map
  factory NPSServer.fromMap(Map<String, dynamic> map) {
    return NPSServer(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String,
      originalId: map['original_id'] as String?,
      hireDate: DateTime.parse(map['hire_date'] as String),
      active: (map['active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert NPSServer to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (originalId != null) 'original_id': originalId,
      'hire_date':
          hireDate.toIso8601String().split('T')[0], // Store as YYYY-MM-DD
      'active': active ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this server with updated fields
  NPSServer copyWith({
    String? id,
    String? name,
    DateTime? hireDate,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NPSServer(
      id: id ?? this.id,
      name: name ?? this.name,
      hireDate: hireDate ?? this.hireDate,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'NPSServer{id: $id, name: $name, hireDate: $hireDate, active: $active}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NPSServer &&
        other.id == id &&
        other.name == name &&
        other.hireDate == hireDate &&
        other.active == active;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, hireDate, active);
  }

  /// Validation methods

  /// Check if the server data is valid
  bool isValid() {
    return name.trim().isNotEmpty &&
        hireDate.isBefore(DateTime.now().add(const Duration(days: 1)));
  }

  /// Get validation errors
  List<String> getValidationErrors() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Server name cannot be empty');
    }

    if (name.trim().length > 100) {
      errors.add('Server name cannot exceed 100 characters');
    }

    if (hireDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      errors.add('Hire date cannot be in the future');
    }

    return errors;
  }

  /// Business logic methods

  /// Calculate tenure in days
  int getTenureInDays([DateTime? asOfDate]) {
    final referenceDate = asOfDate ?? DateTime.now();
    return referenceDate.difference(hireDate).inDays;
  }

  /// Calculate tenure in months (approximate)
  int getTenureInMonths([DateTime? asOfDate]) {
    final referenceDate = asOfDate ?? DateTime.now();
    final months = (referenceDate.year - hireDate.year) * 12 +
        (referenceDate.month - hireDate.month);
    return months;
  }

  /// Check if server was hired before a specific date
  bool wasHiredBefore(DateTime date) {
    return hireDate.isBefore(date);
  }

  /// Check if server was hired after a specific date
  bool wasHiredAfter(DateTime date) {
    return hireDate.isAfter(date);
  }

  /// Get display name for UI
  String get displayName => name.trim();

  /// Get formatted hire date
  String get formattedHireDate {
    return '${hireDate.year}-${hireDate.month.toString().padLeft(2, '0')}-${hireDate.day.toString().padLeft(2, '0')}';
  }

  /// Check if server is eligible for NPS tracking
  /// (Must be active and hired for at least 1 day)
  bool get isEligibleForNPS {
    return active && getTenureInDays() >= 1;
  }
}
