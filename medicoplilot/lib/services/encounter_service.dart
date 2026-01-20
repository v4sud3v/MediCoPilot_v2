import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class VitalSigns {
  final double? temperature;
  final String? bloodPressure;
  final double? heartRate;
  final double? respiratoryRate;
  final double? oxygenSaturation;
  final double? weight;
  final double? height;

  VitalSigns({
    this.temperature,
    this.bloodPressure,
    this.heartRate,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      if (temperature != null) 'temperature': temperature,
      if (bloodPressure != null) 'blood_pressure': bloodPressure,
      if (heartRate != null) 'heart_rate': heartRate,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (oxygenSaturation != null) 'oxygen_saturation': oxygenSaturation,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
    };
  }
}

class MissedDiagnosis {
  final String title;
  final String description;
  final String confidence;

  MissedDiagnosis({
    required this.title,
    required this.description,
    required this.confidence,
  });

  factory MissedDiagnosis.fromJson(Map<String, dynamic> json) {
    return MissedDiagnosis(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      confidence: json['confidence'] ?? 'Medium',
    );
  }
}

class PotentialIssue {
  final String title;
  final String description;
  final String severity;

  PotentialIssue({
    required this.title,
    required this.description,
    required this.severity,
  });

  factory PotentialIssue.fromJson(Map<String, dynamic> json) {
    return PotentialIssue(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'Medium',
    );
  }
}

class RecommendedTest {
  final String title;
  final String description;
  final String priority;

  RecommendedTest({
    required this.title,
    required this.description,
    required this.priority,
  });

  factory RecommendedTest.fromJson(Map<String, dynamic> json) {
    return RecommendedTest(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'Medium',
    );
  }
}

class AnalysisResponse {
  final List<MissedDiagnosis> missedDiagnoses;
  final List<PotentialIssue> potentialIssues;
  final List<RecommendedTest> recommendedTests;

  AnalysisResponse({
    required this.missedDiagnoses,
    required this.potentialIssues,
    required this.recommendedTests,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      missedDiagnoses: (json['missedDiagnoses'] as List?)
              ?.map((e) => MissedDiagnosis.fromJson(e))
              .toList() ??
          [],
      potentialIssues: (json['potentialIssues'] as List?)
              ?.map((e) => PotentialIssue.fromJson(e))
              .toList() ??
          [],
      recommendedTests: (json['recommendedTests'] as List?)
              ?.map((e) => RecommendedTest.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'missedDiagnoses': missedDiagnoses
          .map((e) => {
                'title': e.title,
                'description': e.description,
                'confidence': e.confidence,
              })
          .toList(),
      'potentialIssues': potentialIssues
          .map((e) => {
                'title': e.title,
                'description': e.description,
                'severity': e.severity,
              })
          .toList(),
      'recommendedTests': recommendedTests
          .map((e) => {
                'title': e.title,
                'description': e.description,
                'priority': e.priority,
              })
          .toList(),
    };
  }
}

class PatientData {
  final String name;
  final int? age;
  final String? gender;
  final String? allergies;
  final String? contactInfo;

  PatientData({
    required this.name,
    this.age,
    this.gender,
    this.allergies,
    this.contactInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (allergies != null) 'allergies': allergies,
      if (contactInfo != null) 'contact_info': contactInfo,
    };
  }
}

class SaveEncounterResponse {
  final bool success;
  final String encounterId;
  final String patientId;
  final String caseId;
  final int visitNumber;
  final String message;

  SaveEncounterResponse({
    required this.success,
    required this.encounterId,
    required this.patientId,
    required this.caseId,
    required this.visitNumber,
    required this.message,
  });

  factory SaveEncounterResponse.fromJson(Map<String, dynamic> json) {
    return SaveEncounterResponse(
      success: json['success'] ?? false,
      encounterId: json['encounter_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      caseId: json['case_id'] ?? '',
      visitNumber: json['visit_number'] ?? 1,
      message: json['message'] ?? '',
    );
  }
}

class EncounterService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<SaveEncounterResponse> saveEncounter({
    required String doctorId,
    required PatientData patient,
    String? chiefComplaint,
    String? historyOfIllness,
    required VitalSigns vitalSigns,
    String? physicalExam,
    String? diagnosis,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/encounter/save');
      
      final requestBody = {
        'doctor_id': doctorId,
        'patient': patient.toJson(),
        if (chiefComplaint != null && chiefComplaint.isNotEmpty)
          'chief_complaint': chiefComplaint,
        if (historyOfIllness != null && historyOfIllness.isNotEmpty)
          'history_of_illness': historyOfIllness,
        'vital_signs': vitalSigns.toJson(),
        if (physicalExam != null && physicalExam.isNotEmpty)
          'physical_exam': physicalExam,
        if (diagnosis != null && diagnosis.isNotEmpty) 'diagnosis': diagnosis,
      };

      print('🔵 Sending save request to: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
      );

      print('📥 Save response status: ${response.statusCode}');
      print('📥 Save response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return SaveEncounterResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to save encounter: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error in saveEncounter: $e');
      rethrow;
    }
  }

  Future<AnalysisResponse> analyzeEncounter({
    required String patientId,
    required String diagnosis,
    required String symptoms,
    required VitalSigns vitalSigns,
    String? examinationFindings,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/analysis/encounter');
      
      final requestBody = {
        'patient_id': patientId,
        'diagnosis': diagnosis,
        'symptoms': symptoms,
        'vital_signs': vitalSigns.toJson(),
        if (examinationFindings != null && examinationFindings.isNotEmpty)
          'examination_findings': examinationFindings,
      };

      print('🔵 Sending request to: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(minutes: 5), // Local LLM can take 2-3 minutes
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AnalysisResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to analyze encounter: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error in analyzeEncounter: $e');
      rethrow;
    }
  }
}
