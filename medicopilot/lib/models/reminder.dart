/// Reminder event type
enum ReminderEventType {
  followUp,
  test,
  medication,
  other;

  String get displayName {
    switch (this) {
      case ReminderEventType.followUp:
        return 'follow-up';
      case ReminderEventType.test:
        return 'test';
      case ReminderEventType.medication:
        return 'medication';
      case ReminderEventType.other:
        return 'other';
    }
  }

  static ReminderEventType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'follow-up':
        return ReminderEventType.followUp;
      case 'test':
        return ReminderEventType.test;
      case 'medication':
        return ReminderEventType.medication;
      default:
        return ReminderEventType.other;
    }
  }
}

/// Reminder model
class Reminder {
  final String id;
  final String patientId;
  final String patientName;
  final ReminderEventType eventType;
  final DateTime date;
  final String time;
  final String notes;
  final bool completed;

  const Reminder({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.eventType,
    required this.date,
    required this.time,
    required this.notes,
    required this.completed,
  });

  Reminder copyWith({
    String? id,
    String? patientId,
    String? patientName,
    ReminderEventType? eventType,
    DateTime? date,
    String? time,
    String? notes,
    bool? completed,
  }) {
    return Reminder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      eventType: ReminderEventType.fromString(json['eventType'] as String),
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      notes: json['notes'] as String,
      completed: json['completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'eventType': eventType.displayName,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'notes': notes,
      'completed': completed,
    };
  }
}
