/// Data model for Net Promoter Score feedback entries
///
/// This model represents individual guest NPS responses with numerical scores (0-10).
library;

/// Represents an individual NPS feedback entry with numerical score
class NPSScoreFeedback {
  final int? id;
  final int serverId;
  final int score; // 0-10 scale
  final String? comment;
  final DateTime submissionDate;
  final int? guestCount;
  final String? email;
  final String? guestName;
  final DateTime? createdAt;

  const NPSScoreFeedback({
    this.id,
    required this.serverId,
    required this.score,
    this.comment,
    required this.submissionDate,
    this.guestCount,
    this.email,
    this.guestName,
    this.createdAt,
  });

  /// Create NPSScoreFeedback from a database map
  factory NPSScoreFeedback.fromMap(Map<String, dynamic> map) {
    return NPSScoreFeedback(
      id: map['id'] as int?,
      serverId: map['server_id'] as int,
      score: map['score'] as int,
      comment: map['comment'] as String?,
      submissionDate: DateTime.parse(map['submission_date'] as String),
      guestCount: map['guest_count'] as int?,
      email: map['email'] as String?,
      guestName: map['guest_name'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert NPSScoreFeedback to a database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'score': score,
      'comment': comment,
      'submission_date': submissionDate.toIso8601String(),
      'guest_count': guestCount,
      'email': email,
      'guest_name': guestName,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Create a copy with some fields replaced
  NPSScoreFeedback copyWith({
    int? id,
    int? serverId,
    int? score,
    String? comment,
    DateTime? submissionDate,
    int? guestCount,
    String? email,
    String? guestName,
    DateTime? createdAt,
  }) {
    return NPSScoreFeedback(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      submissionDate: submissionDate ?? this.submissionDate,
      guestCount: guestCount ?? this.guestCount,
      email: email ?? this.email,
      guestName: guestName ?? this.guestName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get NPS category based on score
  NPSCategory get category {
    if (score >= 9) return NPSCategory.promoter;
    if (score >= 7) return NPSCategory.passive;
    return NPSCategory.detractor;
  }

  /// Convert to JSON for API calls or exports
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'score': score,
      'comment': comment,
      'submission_date': submissionDate.toIso8601String(),
      'guest_count': guestCount,
      'email': email,
      'guest_name': guestName,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'category': category.name,
    };
  }

  @override
  String toString() {
    return 'NPSScoreFeedback(id: $id, serverId: $serverId, score: $score, comment: $comment, submissionDate: $submissionDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NPSScoreFeedback &&
        other.id == id &&
        other.serverId == serverId &&
        other.score == score &&
        other.comment == comment &&
        other.submissionDate == submissionDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        serverId.hashCode ^
        score.hashCode ^
        comment.hashCode ^
        submissionDate.hashCode;
  }
}

/// NPS category classification
enum NPSCategory {
  promoter('Promoter'),
  passive('Passive'),
  detractor('Detractor');

  const NPSCategory(this.displayName);
  final String displayName;

  /// Get color for UI display
  String get colorHex {
    switch (this) {
      case NPSCategory.promoter:
        return '#4CAF50'; // Green
      case NPSCategory.passive:
        return '#FF9800'; // Orange
      case NPSCategory.detractor:
        return '#F44336'; // Red
    }
  }
}
