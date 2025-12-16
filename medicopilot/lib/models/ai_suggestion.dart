/// AI Suggestion urgency level
enum SuggestionUrgency {
  low,
  medium,
  high;

  String get displayName => name;
}

/// AI Suggestion category
enum SuggestionCategory {
  missedVital,
  redFlag,
  recheckValue,
  documentationGap,
  other;

  String get displayName {
    switch (this) {
      case SuggestionCategory.missedVital:
        return 'missed vital';
      case SuggestionCategory.redFlag:
        return 'red flag';
      case SuggestionCategory.recheckValue:
        return 'recheck value';
      case SuggestionCategory.documentationGap:
        return 'documentation gap';
      case SuggestionCategory.other:
        return 'other';
    }
  }

  static SuggestionCategory fromString(String value) {
    switch (value) {
      case 'missed-vital':
        return SuggestionCategory.missedVital;
      case 'red-flag':
        return SuggestionCategory.redFlag;
      case 'recheck-value':
        return SuggestionCategory.recheckValue;
      case 'documentation-gap':
        return SuggestionCategory.documentationGap;
      default:
        return SuggestionCategory.other;
    }
  }
}

/// AI Suggestion status
enum SuggestionStatus {
  pending,
  accepted,
  ignored;

  String get displayName => name;
}

/// AI Suggestion model
class AISuggestion {
  final String id;
  final String encounterId;
  final SuggestionCategory category;
  final String suggestion;
  final String rationale;
  final SuggestionUrgency urgency;
  final SuggestionStatus status;
  final DateTime createdAt;

  const AISuggestion({
    required this.id,
    required this.encounterId,
    required this.category,
    required this.suggestion,
    required this.rationale,
    required this.urgency,
    required this.status,
    required this.createdAt,
  });

  AISuggestion copyWith({
    String? id,
    String? encounterId,
    SuggestionCategory? category,
    String? suggestion,
    String? rationale,
    SuggestionUrgency? urgency,
    SuggestionStatus? status,
    DateTime? createdAt,
  }) {
    return AISuggestion(
      id: id ?? this.id,
      encounterId: encounterId ?? this.encounterId,
      category: category ?? this.category,
      suggestion: suggestion ?? this.suggestion,
      rationale: rationale ?? this.rationale,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      id: json['id'] as String,
      encounterId: json['encounterId'] as String,
      category: SuggestionCategory.fromString(json['category'] as String),
      suggestion: json['suggestion'] as String,
      rationale: json['rationale'] as String,
      urgency: SuggestionUrgency.values.firstWhere(
        (e) => e.name == json['urgency'],
        orElse: () => SuggestionUrgency.low,
      ),
      status: SuggestionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SuggestionStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'encounterId': encounterId,
      'category': category.displayName,
      'suggestion': suggestion,
      'rationale': rationale,
      'urgency': urgency.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
