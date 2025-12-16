import 'vitals.dart';

/// Encounter status enum
enum EncounterStatus {
  inProgress,
  pendingReview,
  finalized;

  String get displayName {
    switch (this) {
      case EncounterStatus.inProgress:
        return 'in progress';
      case EncounterStatus.pendingReview:
        return 'pending review';
      case EncounterStatus.finalized:
        return 'finalized';
    }
  }

  static EncounterStatus fromString(String value) {
    switch (value) {
      case 'in-progress':
        return EncounterStatus.inProgress;
      case 'pending-review':
        return EncounterStatus.pendingReview;
      case 'finalized':
        return EncounterStatus.finalized;
      default:
        return EncounterStatus.inProgress;
    }
  }
}

/// Encounter model representing a patient encounter
class Encounter {
  final String id;
  final String patientId;
  final String patientName;
  final int age;
  final String gender;
  final DateTime encounterDate;
  final String chiefComplaint;
  final String historyOfPresentIllness;
  final String examinationFindings;
  final Vitals vitals;
  final String provisionalDiagnosis;
  final String medications;
  final String testsOrdered;
  final EncounterStatus status;
  final DateTime createdAt;

  const Encounter({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.encounterDate,
    required this.chiefComplaint,
    required this.historyOfPresentIllness,
    required this.examinationFindings,
    required this.vitals,
    required this.provisionalDiagnosis,
    required this.medications,
    required this.testsOrdered,
    required this.status,
    required this.createdAt,
  });

  factory Encounter.fromJson(Map<String, dynamic> json) {
    return Encounter(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      encounterDate: DateTime.parse(json['encounterDate'] as String),
      chiefComplaint: json['chiefComplaint'] as String,
      historyOfPresentIllness: json['historyOfPresentIllness'] as String,
      examinationFindings: json['examinationFindings'] as String,
      vitals: Vitals.fromJson(json['vitals'] as Map<String, dynamic>),
      provisionalDiagnosis: json['provisionalDiagnosis'] as String,
      medications: json['medications'] as String,
      testsOrdered: json['testsOrdered'] as String,
      status: EncounterStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'encounterDate': encounterDate.toIso8601String(),
      'chiefComplaint': chiefComplaint,
      'historyOfPresentIllness': historyOfPresentIllness,
      'examinationFindings': examinationFindings,
      'vitals': vitals.toJson(),
      'provisionalDiagnosis': provisionalDiagnosis,
      'medications': medications,
      'testsOrdered': testsOrdered,
      'status': status.displayName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
